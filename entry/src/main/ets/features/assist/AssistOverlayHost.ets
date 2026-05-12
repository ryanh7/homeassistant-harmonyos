import { AppRoute } from '../../app/AppRoute';
import { AssistAgentOption, AssistConversationPage, AssistMessage } from './AssistConversationPage';

@Component
export struct AssistOverlayHost {
  @Prop route: number = AppRoute.ASSIST_CONVERSATION;
  @Prop microphoneGranted: boolean = false;
  @Prop listening: boolean = false;
  @Prop pending: boolean = false;
  @Prop textMode: boolean = false;
  @Prop inputText: string = '';
  @Prop errorText: string = '';
  @Prop statusText: string = '';
  @Prop agentName: string = 'Home Assistant';
  @Prop agentLoading: boolean = false;
  @Prop pipelineReady: boolean = false;
  @Prop agentOptions: AssistAgentOption[] = [];
  @Prop selectedAgentId: string = '';
  @Prop messages: AssistMessage[] = [];

  onClose: () => void = () => {};
  onRequestMicrophone: () => void = () => {};
  onToggleMicrophone: () => void = () => {};
  onToggleTextMode: () => void = () => {};
  onInputChange: (value: string) => void = () => {};
  onSendText: () => void = () => {};
  onRefreshAgents: () => void = () => {};
  onSelectAgent: (agentId: string) => void = () => {};

  build() {
    AssistConversationPage({
      microphoneGranted: this.microphoneGranted,
      listening: this.listening,
      pending: this.pending,
      textMode: this.textMode,
      inputText: this.inputText,
      errorText: this.errorText,
      statusText: this.statusText,
      agentName: this.agentName,
      agentLoading: this.agentLoading,
      pipelineReady: this.pipelineReady,
      agentOptions: this.agentOptions,
      selectedAgentId: this.selectedAgentId,
      messages: this.messages,
      onClose: this.onClose,
      onRequestMicrophone: this.onRequestMicrophone,
      onToggleMicrophone: this.onToggleMicrophone,
      onToggleTextMode: this.onToggleTextMode,
      onInputChange: this.onInputChange,
      onSendText: this.onSendText,
      onRefreshAgents: this.onRefreshAgents,
      onSelectAgent: this.onSelectAgent
    })
  }
}
