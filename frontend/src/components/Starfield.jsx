import { useEffect, useRef } from "react";

/**
 * Subtle animated starfield for the SpaceUI hero.
 * - Tiny white dots (1-2px)
 * - Slow parallax drift
 * - Varied opacity 0.2 - 0.8
 */
export default function Starfield({ density = 0.00018, className = "" }) {
  const canvasRef = useRef(null);
  const rafRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    let width = 0;
    let height = 0;
    let stars = [];
    let dpr = Math.min(window.devicePixelRatio || 1, 2);

    const resize = () => {
      const rect = canvas.getBoundingClientRect();
      width = rect.width;
      height = rect.height;
      canvas.width = Math.floor(width * dpr);
      canvas.height = Math.floor(height * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

      const count = Math.max(80, Math.floor(width * height * density));
      stars = new Array(count).fill(0).map(() => spawn());
    };

    const spawn = () => ({
      x: Math.random() * width,
      y: Math.random() * height,
      r: Math.random() * 1.1 + 0.25,
      o: Math.random() * 0.6 + 0.2,
      // depth affects drift speed and twinkle speed
      d: Math.random() * 0.8 + 0.2,
      tw: Math.random() * Math.PI * 2,
    });

    const draw = (t) => {
      ctx.clearRect(0, 0, width, height);
      for (let i = 0; i < stars.length; i++) {
        const s = stars[i];
        // slow parallax drift (downward + slight right)
        s.y += 0.015 * s.d;
        s.x += 0.004 * s.d;
        if (s.y > height + 2) s.y = -2;
        if (s.x > width + 2) s.x = -2;

        // gentle twinkle
        const twinkle = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(t * 0.0008 + s.tw));
        const alpha = s.o * twinkle;

        ctx.beginPath();
        ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255,255,255,${alpha})`;
        ctx.fill();
      }
      rafRef.current = requestAnimationFrame(draw);
    };

    resize();
    rafRef.current = requestAnimationFrame(draw);
    window.addEventListener("resize", resize);
    return () => {
      cancelAnimationFrame(rafRef.current);
      window.removeEventListener("resize", resize);
    };
  }, [density]);

  return (
    <canvas
      ref={canvasRef}
      data-testid="hero-starfield"
      className={className}
      style={{
        position: "absolute",
        inset: 0,
        width: "100%",
        height: "100%",
        pointerEvents: "none",
      }}
      aria-hidden="true"
    />
  );
}
