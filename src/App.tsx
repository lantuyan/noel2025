import { useEffect, useRef } from 'react';
import { Canvas } from '@react-three/fiber';
import * as THREE from 'three';
import { Experience } from './components/3d';
import { GestureController } from './components/GestureController';
import { DebugButton, StatusText, AddPhotoButton, FullscreenPrompt, uiStyles } from './components/UI';
import { useSceneState, useDebugMode, useAIStatus, usePhotos, useZoomState, useTheme, useTreeStyle } from './hooks';

// Import Christmas music
import christmasMusic from './assets/music/Jingle Bells - Oliver Harkell.mp3';

export default function GrandTreeApp() {
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Setup background music with autoplay and loop
  useEffect(() => {
    const audio = new Audio(christmasMusic);
    audio.loop = true;
    audio.volume = 0.5;
    audioRef.current = audio;

    // Try to play immediately (may be blocked by browser)
    const playAudio = () => {
      audio.play().catch(() => {
        // Autoplay was prevented, wait for user interaction
        const handleInteraction = () => {
          audio.play();
          document.removeEventListener('click', handleInteraction);
          document.removeEventListener('touchstart', handleInteraction);
          document.removeEventListener('keydown', handleInteraction);
        };
        document.addEventListener('click', handleInteraction);
        document.addEventListener('touchstart', handleInteraction);
        document.addEventListener('keydown', handleInteraction);
      });
    };

    playAudio();

    // Cleanup on unmount
    return () => {
      audio.pause();
      audio.src = '';
    };
  }, []);
  const { sceneState, setSceneState, toggleSceneState } = useSceneState();
  const { debugMode, toggleDebugMode } = useDebugMode();
  const { aiStatus, setAiStatus } = useAIStatus();
  const { photos, addPhotos } = usePhotos();
  const { zoomState, handlePinch } = useZoomState();
  const { themeColors, cycleTheme } = useTheme();
  const { treeStyle, setStyleByFingerCount } = useTreeStyle();

  const handlePhotosAdded = (files: FileList) => {
    addPhotos(files).catch((error) => {
      console.error('Error adding photos:', error);
      setAiStatus(`ERROR: ${error.message}`);
    });
  };

  return (
    <div style={uiStyles.container}>
      <div
        style={uiStyles.canvasWrapper}
        onDoubleClick={toggleSceneState}>
        <Canvas
          dpr={[1, 2]}
          gl={{ toneMapping: THREE.ReinhardToneMapping }}
          shadows>
          <Experience sceneState={sceneState} photoUrls={photos} zoomState={zoomState} themeColors={themeColors} treeStyle={treeStyle} />
        </Canvas>
      </div>

      <GestureController
        onGesture={setSceneState}
        onStatus={setAiStatus}
        debugMode={debugMode}
        onPinch={handlePinch}
        onThumbUp={cycleTheme}
        onFingerCount={setStyleByFingerCount}
      />

      <div style={uiStyles.buttonContainer}>
        <AddPhotoButton onPhotosAdded={handlePhotosAdded} photoCount={photos.length} />
        <DebugButton debugMode={debugMode} onClick={toggleDebugMode} />
      </div>

      <StatusText aiStatus={aiStatus} />

      <FullscreenPrompt />
    </div>
  );
}
