import { HaConversationAgent } from '../../services/HaApiService';
import { Localization } from '../../shared/i18n/Localization';
import { AssistAgentOption, AssistMessage } from './AssistConversationPage';

export class AssistConversationCoordinator {
  static isPipelineReady(agentsReady: boolean, agents: HaConversationAgent[], loading: boolean): boolean {
    return agentsReady && agents.length > 0 && !loading;
  }

  static hasAgent(agents: HaConversationAgent[], agentId: string): boolean {
    for (let i = 0; i < agents.length; i++) {
      if (agents[i].id === agentId) {
        return true;
      }
    }
    return false;
  }

  static currentAgentName(agents: HaConversationAgent[], agentId: string): string {
    if (agentId.length === 0) {
      return agents.length > 0 ? agents[0].name : 'Home Assistant';
    }
    for (let i = 0; i < agents.length; i++) {
      const agent = agents[i];
      if (agent.id === agentId) {
        return agent.name;
      }
    }
    return agentId;
  }

  static agentOptions(agents: HaConversationAgent[]): AssistAgentOption[] {
    const options: AssistAgentOption[] = [];
    for (let i = 0; i < agents.length; i++) {
      const agent = agents[i];
      options.push({
        id: agent.id,
        name: agent.name
      });
    }
    if (options.length === 0) {
      options.push({
        id: '',
        name: 'Home Assistant'
      });
    }
    return options;
  }

  static defaultMessages(id: number): AssistMessage[] {
    return [
      {
        id,
        role: 'assistant',
        text: Localization.t('assist_default_prompt')
      }
    ];
  }

  static appendMessage(messages: AssistMessage[], id: number, role: string, text: string): AssistMessage[] {
    const value = text.trim();
    if (value.length === 0) {
      return messages;
    }
    const nextMessages = messages.slice();
    nextMessages.push({ id, role, text: value });
    return nextMessages;
  }

  static appendPlaceholder(messages: AssistMessage[], id: number, role: string): AssistMessage[] {
    const nextMessages = messages.slice();
    nextMessages.push({ id, role, text: '' });
    return nextMessages;
  }

  static updateMessage(messages: AssistMessage[], messageId: number, text: string): AssistMessage[] {
    const nextMessages = messages.slice();
    for (let i = 0; i < nextMessages.length; i++) {
      if (nextMessages[i].id === messageId) {
        nextMessages[i] = {
          id: nextMessages[i].id,
          role: nextMessages[i].role,
          text
        };
        return nextMessages;
      }
    }
    return messages;
  }
}
