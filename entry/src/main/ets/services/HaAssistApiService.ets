// Home Assistant Assist pipeline WebSocket client.
// It manages command sequencing, timeout handling, and response parsing for voice/text Assist requests.
import { NetworkService, NetworkWebSocket } from './NetworkService';
import { Localization } from '../shared/i18n/Localization';
import {
  HaAssistPipelineRunResult,
  HaConversationAgent,
  HaConversationAgentsResult
} from './HaApiModels';

interface HaIntentEndParseResult {
  text: string;
  conversationId: string;
}

export class HaAssistApiService {
  static async fetchConversationAgents(
    baseUrl: string,
    accessToken: string
  ): Promise<HaConversationAgentsResult> {
    try {
      const pipelines = await HaAssistApiService.fetchAssistPipelines(baseUrl, accessToken);
      return {
        responseCode: 200,
        agents: pipelines,
        failureSummary: ''
      };
    } catch (err) {
      return {
        responseCode: 0,
        agents: [],
        failureSummary: NetworkService.errorText(err as Error | string | number | boolean)
      };
    }
  }

  static async runAssistPipelineForText(
    baseUrl: string,
    accessToken: string,
    text: string,
    pipelineId: string = '',
    conversationId: string = ''
  ): Promise<HaAssistPipelineRunResult> {
    try {
      return await HaAssistApiService.runAssistPipelineForTextViaWebSocket(
        baseUrl,
        accessToken,
        text,
        pipelineId,
        conversationId
      );
    } catch (err) {
      return {
        success: false,
        text: '',
        conversationId,
        failureSummary: NetworkService.errorText(err as Error | string | number | boolean)
      };
    }
  }

  private static fetchAssistPipelines(baseUrl: string, accessToken: string): Promise<HaConversationAgent[]> {
    return HaAssistApiService.withAuthenticatedWebSocket(baseUrl, accessToken,
      async (client, nextId): Promise<HaConversationAgent[]> => {
        const response = await HaAssistApiService.sendWebSocketCommand(client, nextId(), {
          'type': 'assist_pipeline/pipeline/list'
        });
        const rawResult = HaAssistApiService.objectField(response, 'result');
        if (!rawResult) {
          return [];
        }
        const pipelinesRaw = rawResult['pipelines'];
        if (!Array.isArray(pipelinesRaw)) {
          return [];
        }
        const pipelines: HaConversationAgent[] = [];
        for (let i = 0; i < pipelinesRaw.length; i++) {
          const raw = pipelinesRaw[i] as Record<string, Object | string | number | boolean | null>;
          const rawId = raw['id'];
          if (typeof rawId !== 'string' || rawId.trim().length === 0) {
            continue;
          }
          const rawName = raw['name'];
          pipelines.push({
            id: rawId.trim(),
            name: typeof rawName === 'string' && rawName.trim().length > 0 ? rawName.trim() : rawId.trim()
          });
        }
        return pipelines;
      });
  }

  private static runAssistPipelineForTextViaWebSocket(
    baseUrl: string,
    accessToken: string,
    text: string,
    pipelineId: string,
    conversationId: string
  ): Promise<HaAssistPipelineRunResult> {
    return HaAssistApiService.withAuthenticatedWebSocket(baseUrl, accessToken,
      (client, nextId): Promise<HaAssistPipelineRunResult> => {
        return new Promise<HaAssistPipelineRunResult>((resolve, reject): void => {
          const commandId = nextId();
          let resolved = false;
          let responseText = '';
          let currentConversationId = conversationId;
          const timeoutId = setTimeout((): void => {
            if (!resolved) {
              resolved = true;
              reject(new Error(Localization.t('ha_error_assist_timeout')));
            }
          }, 30000);

          const cleanup = (): void => {
            clearTimeout(timeoutId);
            client.off('message', onMessage);
            client.off('error', onError);
          };
          const finish = (value: HaAssistPipelineRunResult): void => {
            if (resolved) {
              return;
            }
            resolved = true;
            cleanup();
            resolve(value);
          };
          const fail = (err: Error): void => {
            if (resolved) {
              return;
            }
            resolved = true;
            cleanup();
            reject(err);
          };
          const onError = (err: Error): void => {
            fail(err);
          };
          const onMessage = (err: Error, data: string | ArrayBuffer): void => {
            if (err) {
              fail(err);
              return;
            }
            const messageText = HaAssistApiService.webSocketMessageText(data);
            if (messageText.length === 0) {
              return;
            }
            try {
              const message = JSON.parse(messageText) as Record<string, Object | string | number | boolean | null>;
              const rawId = message['id'];
              if (typeof rawId === 'number' && rawId !== commandId) {
                return;
              }
              const type = message['type'];
              if (type === 'result') {
                const success = message['success'];
                if (success === false) {
                  fail(new Error(HaAssistApiService.parseWebSocketError(message)));
                }
                return;
              }
              if (type !== 'event') {
                return;
              }
              const event = HaAssistApiService.objectField(message, 'event');
              if (!event) {
                return;
              }
              const eventType = event['type'];
              if (eventType === 'intent-progress') {
                const chunk = HaAssistApiService.parseIntentProgressChunk(event);
                if (chunk.length > 0) {
                  responseText += chunk;
                }
                return;
              }
              if (eventType === 'intent-end') {
                const parsed = HaAssistApiService.parseIntentEnd(event);
                if (parsed.text.length > 0) {
                  responseText = parsed.text;
                }
                if (parsed.conversationId.length > 0) {
                  currentConversationId = parsed.conversationId;
                }
                return;
              }
              if (eventType === 'error') {
                fail(new Error(HaAssistApiService.parseAssistEventError(event)));
                return;
              }
              if (eventType === 'run-end') {
                if (responseText.trim().length === 0) {
                  fail(new Error(Localization.t('ha_error_assist_no_text')));
                  return;
                }
                finish({
                  success: true,
                  text: responseText.trim(),
                  conversationId: currentConversationId,
                  failureSummary: ''
                });
              }
            } catch (parseErr) {
              fail(new Error(Localization.format('ha_error_assist_parse', 'error',
                NetworkService.errorText(parseErr as Error | string | number | boolean))));
            }
          };

          client.on('message', onMessage);
          client.on('error', onError);

          const input: Record<string, string> = {
            'text': text
          };
          const command: Record<string, Object | string | number | boolean | null> = {
            'type': 'assist_pipeline/run',
            'start_stage': 'intent',
            'end_stage': 'intent',
            'input': input
          };
          if (pipelineId.trim().length > 0) {
            command['pipeline'] = pipelineId.trim();
          }
          if (conversationId.trim().length > 0) {
            command['conversation_id'] = conversationId.trim();
          }
          client.send(JSON.stringify(HaAssistApiService.commandWithId(commandId, command)))
            .catch((sendErr: Error): void => {
              fail(sendErr);
            });
        });
      });
  }

  private static withAuthenticatedWebSocket<T>(
    baseUrl: string,
    accessToken: string,
    action: (client: NetworkWebSocket, nextId: () => number) => Promise<T>
  ): Promise<T> {
    return new Promise<T>((resolve, reject): void => {
      const client = NetworkService.createWebSocket();
      const url = HaAssistApiService.webSocketUrl(baseUrl);
      let messageId = 1;
      let finished = false;
      const timeoutId = setTimeout((): void => {
        if (!finished) {
          finished = true;
          cleanup();
          reject(new Error(Localization.t('ha_error_ws_connect_timeout')));
        }
      }, 15000);

      const nextId = (): number => {
        const value = messageId;
        messageId += 1;
        return value;
      };
      const cleanup = (): void => {
        clearTimeout(timeoutId);
        client.off('message', onMessage);
        client.off('error', onError);
        client.off('close', onClose);
        client.close().catch((): void => {});
      };
      const complete = (value: T): void => {
        if (finished) {
          return;
        }
        finished = true;
        cleanup();
        resolve(value);
      };
      const fail = (err: Error): void => {
        if (finished) {
          return;
        }
        finished = true;
        cleanup();
        reject(err);
      };
      const onError = (err: Error): void => {
        fail(err);
      };
      const onClose = (): void => {
        if (!finished) {
          fail(new Error(Localization.t('ha_error_ws_closed')));
        }
      };
      const onMessage = (err: Error, data: string | ArrayBuffer): void => {
        if (err) {
          fail(err);
          return;
        }
        const messageText = HaAssistApiService.webSocketMessageText(data);
        if (messageText.length === 0) {
          return;
        }
        try {
          const message = JSON.parse(messageText) as Record<string, Object | string | number | boolean | null>;
          const type = message['type'];
          if (type === 'auth_required') {
            client.send(JSON.stringify({
              'type': 'auth',
              'access_token': accessToken
            })).catch((sendErr: Error): void => {
              fail(sendErr);
            });
            return;
          }
          if (type === 'auth_invalid') {
            fail(new Error(HaAssistApiService.parseWebSocketError(message)));
            return;
          }
          if (type === 'auth_ok') {
            action(client, nextId).then((value: T): void => {
              complete(value);
            }).catch((actionErr: Error): void => {
              fail(actionErr);
            });
          }
        } catch (parseErr) {
          fail(new Error(Localization.format('ha_error_ws_handshake_parse', 'error',
            NetworkService.errorText(parseErr as Error | string | number | boolean))));
        }
      };

      client.on('message', onMessage);
      client.on('error', onError);
      client.on('close', onClose);
      client.connect(url, {
        pingInterval: 30,
        pongTimeout: 10
      }).catch((connectErr: Error): void => {
        fail(connectErr);
      });
    });
  }

  private static sendWebSocketCommand(
    client: NetworkWebSocket,
    id: number,
    command: Record<string, Object | string | number | boolean | null>
  ): Promise<Record<string, Object | string | number | boolean | null>> {
    return new Promise<Record<string, Object | string | number | boolean | null>>((resolve, reject): void => {
      let finished = false;
      const timeoutId = setTimeout((): void => {
        if (!finished) {
          finished = true;
          cleanup();
          reject(new Error(Localization.format('ha_error_ws_command_timeout', 'type', `${command['type']}`)));
        }
      }, 15000);
      const cleanup = (): void => {
        clearTimeout(timeoutId);
        client.off('message', onMessage);
        client.off('error', onError);
      };
      const fail = (err: Error): void => {
        if (finished) {
          return;
        }
        finished = true;
        cleanup();
        reject(err);
      };
      const onError = (err: Error): void => {
        fail(err);
      };
      const onMessage = (err: Error, data: string | ArrayBuffer): void => {
        if (err) {
          fail(err);
          return;
        }
        const messageText = HaAssistApiService.webSocketMessageText(data);
        if (messageText.length === 0) {
          return;
        }
        try {
          const message = JSON.parse(messageText) as Record<string, Object | string | number | boolean | null>;
          if (message['type'] !== 'result' || message['id'] !== id) {
            return;
          }
          if (message['success'] === false) {
            fail(new Error(HaAssistApiService.parseWebSocketError(message)));
            return;
          }
          finished = true;
          cleanup();
          resolve(message);
        } catch (parseErr) {
          fail(new Error(Localization.format('ha_error_ws_command_parse', 'error',
            NetworkService.errorText(parseErr as Error | string | number | boolean))));
        }
      };
      client.on('message', onMessage);
      client.on('error', onError);
      client.send(JSON.stringify(HaAssistApiService.commandWithId(id, command))).catch((sendErr: Error): void => {
        fail(sendErr);
      });
    });
  }

  private static commandWithId(
    id: number,
    command: Record<string, Object | string | number | boolean | null>
  ): Record<string, Object | string | number | boolean | null> {
    const payload: Record<string, Object | string | number | boolean | null> = {
      'id': id
    };
    const keys = Object.keys(command);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      payload[key] = command[key];
    }
    return payload;
  }

  private static webSocketUrl(baseUrl: string): string {
    const normalized = baseUrl.replace(/\/+$/, '');
    if (normalized.startsWith('https://')) {
      return `wss://${normalized.slice('https://'.length)}/api/websocket`;
    }
    if (normalized.startsWith('http://')) {
      return `ws://${normalized.slice('http://'.length)}/api/websocket`;
    }
    return `${normalized}/api/websocket`;
  }

  private static webSocketMessageText(data: string | ArrayBuffer): string {
    if (typeof data === 'string') {
      return data;
    }
    return '';
  }

  private static objectField(
    source: Record<string, Object | string | number | boolean | null>,
    key: string
  ): Record<string, Object | string | number | boolean | null> | null {
    const value = source[key];
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, Object | string | number | boolean | null>;
    }
    return null;
  }

  private static parseIntentProgressChunk(
    event: Record<string, Object | string | number | boolean | null>
  ): string {
    const data = HaAssistApiService.objectField(event, 'data');
    if (!data) {
      return '';
    }
    const delta = HaAssistApiService.objectField(data, 'chat_log_delta');
    if (!delta) {
      return '';
    }
    const content = delta['content'];
    return typeof content === 'string' ? content : '';
  }

  private static parseIntentEnd(
    event: Record<string, Object | string | number | boolean | null>
  ): HaIntentEndParseResult {
    const data = HaAssistApiService.objectField(event, 'data');
    const empty: HaIntentEndParseResult = {
      text: '',
      conversationId: ''
    };
    if (!data) {
      return empty;
    }
    let intentOutput = HaAssistApiService.objectField(data, 'intent_output');
    if (!intentOutput) {
      intentOutput = HaAssistApiService.objectField(data, 'intentOutput');
    }
    if (!intentOutput) {
      return empty;
    }
    let rawConversationId = intentOutput['conversation_id'];
    if (typeof rawConversationId !== 'string') {
      rawConversationId = intentOutput['conversationId'];
    }
    const conversationId = typeof rawConversationId === 'string' ? rawConversationId : '';
    let text = '';
    const response = HaAssistApiService.objectField(intentOutput, 'response');
    if (response) {
      const speech = HaAssistApiService.objectField(response, 'speech');
      if (speech) {
        const plain = HaAssistApiService.objectField(speech, 'plain');
        if (plain) {
          const rawSpeech = plain['speech'];
          if (typeof rawSpeech === 'string') {
            text = rawSpeech;
          }
        }
      }
    }
    return {
      text,
      conversationId
    };
  }

  private static parseAssistEventError(
    event: Record<string, Object | string | number | boolean | null>
  ): string {
    const data = HaAssistApiService.objectField(event, 'data');
    if (!data) {
      return Localization.t('ha_error_assist_pipeline');
    }
    const message = data['message'];
    if (typeof message === 'string' && message.trim().length > 0) {
      return message.trim();
    }
    const code = data['code'];
    if (typeof code === 'string' && code.trim().length > 0) {
      return code.trim();
    }
    return Localization.t('ha_error_assist_pipeline');
  }

  private static parseWebSocketError(
    message: Record<string, Object | string | number | boolean | null>
  ): string {
    const rawMessage = message['message'];
    if (typeof rawMessage === 'string' && rawMessage.trim().length > 0) {
      return rawMessage.trim();
    }
    const error = HaAssistApiService.objectField(message, 'error');
    if (error) {
      const errorMessage = error['message'];
      if (typeof errorMessage === 'string' && errorMessage.trim().length > 0) {
        return errorMessage.trim();
      }
      const code = error['code'];
      if (typeof code === 'string' && code.trim().length > 0) {
        return code.trim();
      }
    }
    return Localization.t('ha_error_ws_request');
  }

}
