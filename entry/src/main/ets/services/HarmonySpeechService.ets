import audio from '@ohos.multimedia.audio';
import { speechRecognizer, textToSpeech } from '@kit.CoreSpeechKit';
import { Localization } from '../shared/i18n/Localization';

export interface HarmonySpeechRecognitionCallbacks {
  onStatus: (message: string) => void;
  onPartial: (text: string) => void;
  onFinal: (text: string) => void;
  onComplete: (text: string) => void;
  onError: (message: string) => void;
}

export interface HarmonySpeechSpeakCallbacks {
  onStart: () => void;
  onComplete: () => void;
  onError: (message: string) => void;
}

export class HarmonySpeechService {
  private recognizer: speechRecognizer.SpeechRecognitionEngine | undefined = undefined;
  private tts: textToSpeech.TextToSpeechEngine | undefined = undefined;
  private capturer: audio.AudioCapturer | undefined = undefined;
  private readDataCallback: ((buffer: ArrayBuffer) => void) | undefined = undefined;
  private recognitionCallbacks: HarmonySpeechRecognitionCallbacks | undefined = undefined;
  private sessionId: string = '';
  private recognizing: boolean = false;
  private lastText: string = '';
  private audioRemainder: Uint8Array = new Uint8Array(0);

  async startRecognition(callbacks: HarmonySpeechRecognitionCallbacks): Promise<void> {
    await this.stopRecognition(false);
    this.recognitionCallbacks = callbacks;
    this.sessionId = `ha_assist_${Date.now()}`;
    this.lastText = '';
    this.audioRemainder = new Uint8Array(0);
    this.recognizing = true;
    callbacks.onStatus(Localization.t('speech_starting_recognition'));

    try {
      const recognizer = await this.ensureRecognizer();
      recognizer.setListener(this.recognitionListener());
      recognizer.startListening({
        sessionId: this.sessionId,
        audioInfo: {
          audioType: 'pcm',
          sampleRate: 16000,
          soundChannel: 1,
          sampleBit: 16
        }
      });
      await this.startCapturer();
      callbacks.onStatus(Localization.t('speech_listening'));
    } catch (err) {
      this.recognizing = false;
      await this.releaseCapturer();
      callbacks.onError(this.errorText(err));
    }
  }

  async stopRecognition(sendFinal: boolean): Promise<void> {
    const activeSession = this.sessionId;
    const recognizer = this.recognizer;
    this.recognizing = false;
    await this.releaseCapturer();
    if (recognizer && activeSession.length > 0) {
      try {
        if (sendFinal) {
          recognizer.finish(activeSession);
        } else {
          recognizer.cancel(activeSession);
        }
      } catch (_) {
      }
    }
    if (!sendFinal) {
      this.sessionId = '';
      this.lastText = '';
    }
  }

  async speak(text: string, callbacks: HarmonySpeechSpeakCallbacks): Promise<void> {
    const value = text.trim();
    if (value.length === 0) {
      return;
    }
    try {
      const engine = await this.ensureTts();
      const requestId = `ha_tts_${Date.now()}`;
      engine.setListener({
        onStart: (): void => {
          callbacks.onStart();
        },
        onComplete: (): void => {
          callbacks.onComplete();
        },
        onStop: (): void => {
          callbacks.onComplete();
        },
        onError: (_requestId: string, errorCode: number, errorMessage: string): void => {
          callbacks.onError(Localization.format2('speech_tts_failed', 'code', errorCode, 'message', errorMessage));
        }
      });
      engine.speak(value, {
        requestId,
        extraParams: {
          queueMode: 0,
          speed: 1,
          volume: 2,
          pitch: 1,
          languageContext: 'zh-CN',
          audioType: 'pcm',
          soundChannel: 3,
          playType: 1
        }
      });
    } catch (err) {
      callbacks.onError(this.errorText(err));
    }
  }

  stopSpeaking(): void {
    try {
      this.tts?.stop();
    } catch (_) {
    }
  }

  shutdown(): void {
    this.stopSpeaking();
    this.stopRecognition(false).catch((): void => {});
    try {
      this.recognizer?.shutdown();
    } catch (_) {
    }
    try {
      this.tts?.shutdown();
    } catch (_) {
    }
    this.recognizer = undefined;
    this.tts = undefined;
  }

  private async ensureRecognizer(): Promise<speechRecognizer.SpeechRecognitionEngine> {
    if (this.recognizer) {
      return this.recognizer;
    }
    const engine = await this.createRecognizer();
    this.recognizer = engine;
    return engine;
  }

  private async ensureTts(): Promise<textToSpeech.TextToSpeechEngine> {
    if (this.tts) {
      return this.tts;
    }
    const engine = await this.createTts();
    this.tts = engine;
    return engine;
  }

  private async createRecognizer(): Promise<speechRecognizer.SpeechRecognitionEngine> {
    try {
      return await speechRecognizer.createEngine({
        language: 'zh-CN',
        online: 1
      });
    } catch (error) {
      throw this.errorFrom(error);
    }
  }

  private async createTts(): Promise<textToSpeech.TextToSpeechEngine> {
    try {
      return await textToSpeech.createEngine({
        language: 'zh-CN',
        person: 0,
        online: 1,
        extraParams: {
          style: 'interaction-broadcast',
          locate: 'CN',
          name: 'HomeAssistantAssist'
        }
      });
    } catch (error) {
      throw this.errorFrom(error);
    }
  }

  private recognitionListener(): speechRecognizer.RecognitionListener {
    return {
      onStart: (): void => {
        this.recognitionCallbacks?.onStatus(Localization.t('speech_listening'));
      },
      onEvent: (_sessionId: string, eventCode: number): void => {
        if (eventCode === 1) {
          this.recognitionCallbacks?.onStatus(Localization.t('speech_detected'));
        } else if (eventCode === 3) {
          this.recognitionCallbacks?.onStatus(Localization.t('speech_processing'));
        }
      },
      onResult: (_sessionId: string, result: speechRecognizer.SpeechRecognitionResult): void => {
        const text = result.result.trim();
        if (text.length === 0) {
          return;
        }
        this.lastText = text;
        if (result.isFinal || result.isLast) {
          this.recognitionCallbacks?.onFinal(text);
        } else {
          this.recognitionCallbacks?.onPartial(text);
        }
      },
      onComplete: (): void => {
        const text = this.lastText.trim();
        this.recognizing = false;
        this.releaseCapturer().catch((): void => {});
        this.sessionId = '';
        this.recognitionCallbacks?.onComplete(text);
      },
      onError: (_sessionId: string, errorCode: number, errorMessage: string): void => {
        this.recognizing = false;
        this.releaseCapturer().catch((): void => {});
        this.sessionId = '';
        this.recognitionCallbacks?.onError(Localization.format2('speech_recognition_failed', 'code', errorCode, 'message', errorMessage));
      }
    };
  }

  private async startCapturer(): Promise<void> {
    const options: audio.AudioCapturerOptions = {
      streamInfo: {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      },
      capturerInfo: {
        source: audio.SourceType.SOURCE_TYPE_VOICE_RECOGNITION,
        capturerFlags: 0
      }
    };
    const capturer = await this.createCapturer(options);
    this.capturer = capturer;
    this.readDataCallback = (buffer: ArrayBuffer): void => {
      this.writeAudio(buffer);
    };
    this.registerReadDataCallback(capturer, this.readDataCallback);
    await this.startAudioCapturer(capturer);
  }

  private async releaseCapturer(): Promise<void> {
    if (!this.capturer) {
      return;
    }
    try {
      if (this.readDataCallback) {
        this.capturer.off('readData', this.readDataCallback);
      }
    } catch (_) {
    }
    try {
      await this.capturer.stop();
    } catch (_) {
    }
    try {
      await this.capturer.release();
    } catch (_) {
    }
    this.capturer = undefined;
    this.readDataCallback = undefined;
    this.audioRemainder = new Uint8Array(0);
  }

  private writeAudio(buffer: ArrayBuffer): void {
    if (!this.recognizing || !this.recognizer || this.sessionId.length === 0 || buffer.byteLength === 0) {
      return;
    }
    const input = new Uint8Array(buffer);
    const merged = new Uint8Array(this.audioRemainder.length + input.length);
    merged.set(this.audioRemainder, 0);
    merged.set(input, this.audioRemainder.length);

    const chunkSize = 1280;
    let offset = 0;
    while (offset + chunkSize <= merged.length) {
      const chunk = merged.slice(offset, offset + chunkSize);
      try {
        this.recognizer.writeAudio(this.sessionId, chunk);
      } catch (err) {
        this.recognitionCallbacks?.onError(this.errorText(err));
        this.stopRecognition(false).catch((): void => {});
        return;
      }
      offset += chunkSize;
    }
    this.audioRemainder = merged.slice(offset);
  }

  private errorText(err: Object | string | number | boolean): string {
    if (err instanceof Error) {
      return err.message ? `${err.name}: ${err.message}` : err.name;
    }
    try {
      return JSON.stringify(err);
    } catch (_) {
      return String(err);
    }
  }

  private async createCapturer(options: audio.AudioCapturerOptions): Promise<audio.AudioCapturer> {
    try {
      return await audio.createAudioCapturer(options);
    } catch (error) {
      throw this.errorFrom(error);
    }
  }

  private registerReadDataCallback(capturer: audio.AudioCapturer, callback: (buffer: ArrayBuffer) => void): void {
    try {
      capturer.on('readData', callback);
    } catch (error) {
      throw this.errorFrom(error);
    }
  }

  private async startAudioCapturer(capturer: audio.AudioCapturer): Promise<void> {
    try {
      await capturer.start();
    } catch (error) {
      throw this.errorFrom(error);
    }
  }

  private errorFrom(error: Error): Error {
    return error;
  }
}
