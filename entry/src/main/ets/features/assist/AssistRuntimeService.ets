import {
  HaApiService,
  HaAssistPipelineRunResult,
  HaConversationAgent,
  HaConversationAgentsResult
} from '../../services/HaApiService';
import { AssistConversationCoordinator } from './AssistConversationCoordinator';
import { AssistMessage } from './AssistConversationPage';

export interface AssistOpenState {
  inputText: string;
  responseText: string;
  errorText: string;
  statusText: string;
  pending: boolean;
  listening: boolean;
  textMode: boolean;
  messageId: number;
  conversationId: string;
  voiceInputMessageId: number;
  pendingStartListening: boolean;
  messages: AssistMessage[];
}

export interface AssistAgentState {
  agents: HaConversationAgent[];
  ready: boolean;
  selectedAgentId: string;
}

export class AssistRuntimeService {
  static openState(startListening: boolean): AssistOpenState {
    const messageId = 1;
    return {
      inputText: '',
      responseText: '',
      errorText: '',
      statusText: '',
      pending: false,
      listening: false,
      textMode: false,
      messageId: messageId + 1,
      conversationId: '',
      voiceInputMessageId: 0,
      pendingStartListening: startListening,
      messages: AssistConversationCoordinator.defaultMessages(messageId)
    };
  }

  static canSkipAgentRefresh(
    force: boolean,
    ready: boolean,
    agents: HaConversationAgent[],
    loading: boolean
  ): boolean {
    return !force && AssistConversationCoordinator.isPipelineReady(ready, agents, loading);
  }

  static agentStateFromResult(
    result: HaConversationAgentsResult,
    selectedAgentId: string
  ): AssistAgentState {
    if (result.failureSummary.length > 0) {
      return {
        agents: [],
        ready: false,
        selectedAgentId
      };
    }
    const stillValid = selectedAgentId.length === 0 ||
      AssistConversationCoordinator.hasAgent(result.agents, selectedAgentId);
    return {
      agents: result.agents,
      ready: result.agents.length > 0,
      selectedAgentId: stillValid ? selectedAgentId : ''
    };
  }

  static async fetchAgents(baseUrl: string, token: string): Promise<HaConversationAgentsResult> {
    return HaApiService.fetchConversationAgents(baseUrl, token);
  }

  static async runTextPipeline(
    baseUrl: string,
    token: string,
    text: string,
    agentId: string,
    conversationId: string
  ): Promise<HaAssistPipelineRunResult> {
    return HaApiService.runAssistPipelineForText(baseUrl, token, text, agentId, conversationId);
  }
}
