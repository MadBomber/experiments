// app/javascript/channels/open_ai_channel.js

import consumer from "./consumer";

let subscription = null;

document.addEventListener("DOMContentLoaded", () => {
  subscription = consumer.subscriptions.create("OpenAiChannel", {
    connected() {
      console.log("Connected to OpenAI channel");
    },

    disconnected() {
      console.log("Disconnected from OpenAI channel");
    },

    sendAudio(audioData) {
      this.perform("append_audio", { type: "audio", audio: audioData });
    },

    closeSession() {
      this.perform("close_session");
    },

    restartSession() {
      this.perform("restart_session");
    },
    received(data) {
      // Called when there's incoming data on the websocket for this channel
      console.log("Received data:", data);
      if (data.type === "audio") {
        playAudioDelta(data.data);
      }

      if (data.type === "input_audio_buffer.speech_started") {
        console.log("Speech started");
        this.perform("cancel_response");
        window.stopAudioPlayback();
      }
    },
  });

  // Button elements
  const startButton = document.getElementById("start-recording");
  const stopButton = document.getElementById("stop-recording");

  let audioContext;

  // Converts Float32Array of audio data to PCM16 ArrayBuffer
  function floatTo16BitPCM(float32Array) {
    const buffer = new ArrayBuffer(float32Array.length * 2);
    const view = new DataView(buffer);
    let offset = 0;
    for (let i = 0; i < float32Array.length; i++, offset += 2) {
      let s = Math.max(-1, Math.min(1, float32Array[i]));
      view.setInt16(offset, s < 0 ? s * 0x8000 : s * 0x7fff, true);
    }
    return buffer;
  }

  // Converts a Float32Array to base64-encoded PCM16 data
  function base64EncodeAudio(float32Array) {
    const arrayBuffer = floatTo16BitPCM(float32Array);
    let binary = "";
    let bytes = new Uint8Array(arrayBuffer);
    const chunkSize = 0x8000; // 32KB chunk size
    for (let i = 0; i < bytes.length; i += chunkSize) {
      let chunk = bytes.subarray(i, i + chunkSize);
      binary += String.fromCharCode.apply(null, chunk);
    }
    return btoa(binary);
  }

  startButton.onclick = async () => {
    audioContext = new (window.AudioContext || window.webkitAudioContext)({
      sampleRate: 24000,
    });
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        channelCount: 1,
        sampleRate: 24000,
        sampleSize: 16,
      },
    });
    const source = audioContext.createMediaStreamSource(stream);
    const processor = audioContext.createScriptProcessor(1024, 1, 1);

    source.connect(processor);
    processor.connect(audioContext.destination);

    // Send audio chunks continuously as they are processed
    processor.onaudioprocess = (e) => {
      const inputData = e.inputBuffer.getChannelData(0);
      const encodedAudio = base64EncodeAudio(new Float32Array(inputData));
      subscription.sendAudio(encodedAudio); // Send audio data via WebSocket
    };

    startButton.disabled = true;
    stopButton.disabled = false;
  };

  stopButton.onclick = () => {
    audioContext.close();
    startButton.disabled = false;
    stopButton.disabled = true;
    closeSession();
  };
});
