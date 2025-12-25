import { useState, useEffect } from 'react';

export const FullscreenPrompt = () => {
    const [showPrompt, setShowPrompt] = useState(false);

    useEffect(() => {
        // Check if on mobile device
        const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

        // Check if already in fullscreen
        const isFullscreen = () => {
            return !!(
                document.fullscreenElement ||
                (document as any).webkitFullscreenElement ||
                (document as any).mozFullScreenElement ||
                (document as any).msFullscreenElement
            );
        };

        // Only show prompt on mobile if not in fullscreen
        if (isMobile && !isFullscreen()) {
            // Delay showing prompt to let the page load
            const timer = setTimeout(() => {
                setShowPrompt(true);
            }, 1000);
            return () => clearTimeout(timer);
        }
    }, []);

    const requestFullscreen = async () => {
        try {
            const elem = document.documentElement;
            if (elem.requestFullscreen) {
                await elem.requestFullscreen();
            } else if ((elem as any).webkitRequestFullscreen) {
                await (elem as any).webkitRequestFullscreen();
            } else if ((elem as any).mozRequestFullScreen) {
                await (elem as any).mozRequestFullScreen();
            } else if ((elem as any).msRequestFullscreen) {
                await (elem as any).msRequestFullscreen();
            }
            setShowPrompt(false);
        } catch (error) {
            console.error('Fullscreen request failed:', error);
            setShowPrompt(false);
        }
    };

    const dismissPrompt = () => {
        setShowPrompt(false);
    };

    if (!showPrompt) return null;

    return (
        <div style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.85)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
            padding: '20px',
        }}>
            <div style={{
                backgroundColor: 'rgba(30, 30, 30, 0.95)',
                borderRadius: '20px',
                padding: '32px 24px',
                maxWidth: '320px',
                textAlign: 'center',
                border: '1px solid rgba(255, 215, 0, 0.3)',
                boxShadow: '0 20px 60px rgba(0, 0, 0, 0.5)',
            }}>
                {/* Christmas Tree Icon */}
                <div style={{
                    fontSize: '48px',
                    marginBottom: '16px',
                }}>
                    🎄
                </div>

                <h2 style={{
                    color: '#FFD700',
                    fontSize: '20px',
                    fontWeight: '700',
                    margin: '0 0 12px 0',
                }}>
                    Fullscreen Mode
                </h2>

                <p style={{
                    color: 'rgba(255, 255, 255, 0.8)',
                    fontSize: '14px',
                    margin: '0 0 24px 0',
                    lineHeight: '1.5',
                }}>
                    For the best experience, view the Christmas Tree in fullscreen mode
                </p>

                <div style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '12px',
                }}>
                    <button
                        onClick={requestFullscreen}
                        style={{
                            padding: '14px 24px',
                            backgroundColor: '#FFD700',
                            border: 'none',
                            borderRadius: '12px',
                            color: '#000',
                            fontSize: '16px',
                            fontWeight: '700',
                            cursor: 'pointer',
                            transition: 'all 0.3s ease',
                        }}
                    >
                        ✨ Enter Fullscreen
                    </button>

                    <button
                        onClick={dismissPrompt}
                        style={{
                            padding: '12px 24px',
                            backgroundColor: 'transparent',
                            border: '1px solid rgba(255, 255, 255, 0.2)',
                            borderRadius: '12px',
                            color: 'rgba(255, 255, 255, 0.6)',
                            fontSize: '14px',
                            fontWeight: '500',
                            cursor: 'pointer',
                            transition: 'all 0.3s ease',
                        }}
                    >
                        Maybe Later
                    </button>
                </div>
            </div>
        </div>
    );
};
