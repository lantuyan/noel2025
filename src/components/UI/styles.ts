import type { CSSProperties } from 'react';

export const uiStyles = {
  container: {
    width: '100vw',
    height: '100vh',
    backgroundColor: '#000',
    position: 'relative',
    overflow: 'hidden'
  } as CSSProperties,

  canvasWrapper: {
    width: '100%',
    height: '100%',
    position: 'absolute',
    top: 0,
    left: 0,
    zIndex: 1,
    cursor: 'pointer'
  } as CSSProperties,

  buttonContainer: {
    position: 'absolute',
    bottom: 'max(16px, env(safe-area-inset-bottom, 16px))',
    right: 'max(16px, env(safe-area-inset-right, 16px))',
    left: 'max(16px, env(safe-area-inset-left, 16px))',
    zIndex: 10,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '12px',
    flexWrap: 'wrap'
  } as CSSProperties
};

