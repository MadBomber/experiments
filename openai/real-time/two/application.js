/* eslint no-console:0 */

import "@hotwired/turbo-rails";
import SiriWave from "siriwave";

require("@rails/activestorage").start();
require("local-time").start();

import "./channels";
import "./controllers";
import "./src/**/*";


var siriWave = new SiriWave({
  container: document.getElementById("siri-container"),
  style: "ios",
  color: "#4ade80",
  cover: true,
  height: 200,
  speed: 0.3,
});

siriWave.setAmplitude(0);
siriWave.start();

document.addEventListener("turbo:load", () => {
  let audioContext;
  let audioBuffer = new Float32Array(0); // Continuous buffer to store audio samples
  let isPlaying = false;
  let scriptProcessor;
  let analyserNode;
  let amplitudeData;

  function initAudioContext() {
    if (!audioContext) {
      audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: 24000, // Match the sample rate to the incoming audio
      });
      console.log(
        "AudioContext initialized with sample rate:",
        audioContext.sampleRate,
      );

      // Create a ScriptProcessorNode for real-time audio playback
      scriptProcessor = audioContext.createScriptProcessor(4096, 1, 1);
      scriptProcessor.connect(audioContext.destination);
      scriptProcessor.onaudioprocess = handleAudioProcess;

      // Create an AnalyserNode to analyse the audio signal
      analyserNode = audioContext.createAnalyser();
      analyserNode.fftSize = 256; // Controls the granularity of the analysis
      amplitudeData = new Uint8Array(analyserNode.frequencyBinCount);

      // Connect the analyser to the script processor
      scriptProcessor.connect(analyserNode);
      analyserNode.connect(audioContext.destination);
    }
  }

  function handleAudioProcess(event) {
    const outputBuffer = event.outputBuffer.getChannelData(0);
    const bufferLength = outputBuffer.length;

    if (audioBuffer.length >= bufferLength) {
      // Copy data from the audioBuffer to the output buffer
      outputBuffer.set(audioBuffer.subarray(0, bufferLength));

      // Remove the played samples from the audioBuffer
      audioBuffer = audioBuffer.subarray(bufferLength);
    } else {
      // If there is not enough audio left, fill with silence
      outputBuffer.set(audioBuffer);
      audioBuffer = new Float32Array(0); // Clear the buffer once all audio has been played
    }

    if (audioBuffer.length === 0) {
      isPlaying = false;
    }

    // Get the amplitude data
    analyserNode.getByteTimeDomainData(amplitudeData);

    // Calculate the average amplitude (RMS)
    let sum = 0;
    for (let i = 0; i < amplitudeData.length; i++) {
      const value = (amplitudeData[i] - 128) / 128; // Normalize the data to [-1, 1]
      sum += value * value;
    }
    const rms = Math.sqrt(sum / amplitudeData.length);
    console.log("Current amplitude (RMS):", rms);
    siriWave.setAmplitude(rms * 20.0);
  }

  window.playAudioDelta = function (audioData) {
    console.log("Received audio data length:", audioData.length);

    if (!audioData || typeof audioData !== "string") {
      console.error("Invalid audioData:", audioData);
      return;
    }

    try {
      initAudioContext();

      let base64String = audioData.replace(/-/g, "+").replace(/_/g, "/");
      while (base64String.length % 4 !== 0) {
        base64String += "=";
      }
      base64String = base64String.replace(/[^A-Za-z0-9+/=]/g, "");

      const binaryString = atob(base64String);
      const bytes = new Uint8Array(binaryString.length);
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
      }

      const buffer = bytes.buffer;
      const numOfSamples = Math.floor(buffer.byteLength / 2); // Ensure integer number of samples
      const dataView = new DataView(buffer);
      const newSamples = new Float32Array(numOfSamples);

      for (let i = 0; i < numOfSamples; i++) {
        const sample = dataView.getInt16(i * 2, true);
        newSamples[i] = sample / 32768; // Normalize 16-bit PCM to float [-1.0, 1.0]
      }

      // Append the new samples to the existing audio buffer
      const updatedBuffer = new Float32Array(
        audioBuffer.length + newSamples.length,
      );
      updatedBuffer.set(audioBuffer);
      updatedBuffer.set(newSamples, audioBuffer.length);
      audioBuffer = updatedBuffer;

      console.log(
        "Audio chunk added to buffer. Buffer length (samples):",
        audioBuffer.length,
      );

      if (!isPlaying) {
        isPlaying = true;
        console.log("Starting playback");
      }
    } catch (error) {
      console.error("Error processing audio data:", error);
    }
  };

  window.stopAudioPlayback = function () {
    console.log("Stopping audio playback");
    isPlaying = false;
    audioBuffer = new Float32Array(0); // Clear buffer
    if (audioContext) {
      audioContext.close().then(() => {
        audioContext = null;
        console.log("AudioContext closed and playback stopped.");
      });
    }
  };

  initAudioContext();
  console.log("Audio playback system initialized");
});

function handleWebSocketMessage(data) {
  console.log("Received WebSocket message:", data.type);
  if (data.type === "input_audio_buffer.speech_started") {
    window.stopAudioPlayback();
  } else if (data.type === "audio") {
    window.playAudioDelta(data.data);
  }
}
