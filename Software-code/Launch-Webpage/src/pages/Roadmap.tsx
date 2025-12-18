import { useRef, useState, useEffect } from "react";
import { motion, useScroll, useTransform, useSpring, useReducedMotion } from "framer-motion";
import { Layout } from "@/components/layout/Layout";
import { RoadmapNode } from "@/components/RoadmapNode";
import { ROADMAP_PHASES } from "@/config/roadmap";

export default function Roadmap() {
  const containerRef = useRef<HTMLDivElement>(null);
  const prefersReducedMotion = useReducedMotion();
  const [activePhase, setActivePhase] = useState(0);

  // We use a very tall container to allow for "infinite" feeling scroll
  // In reality, we just map the scroll usage to a modulo loop
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  });

  // Smooth out the scroll value
  const smoothProgress = useSpring(scrollYProgress, {
    stiffness: 100,
    damping: 30,
    restDelta: 0.001
  });

  // Calculate active phase for logic/UI (0-9)
  useEffect(() => {
    const unsubscribe = smoothProgress.on("change", (latest) => {
      // Create a theoretical infinite loop by multiplying progress
      // We assume the user won't scroll 1000x the height in one session
      // 10 phases -> map 0..1 to 0..10
      const rawPhase = latest * 50; // multiply by arbitrary loops
      const phaseIndex = Math.floor(rawPhase) % ROADMAP_PHASES.length;
      setActivePhase(phaseIndex);
    });
    return () => unsubscribe();
  }, [smoothProgress]);

  // Reduced motion fallback
  if (prefersReducedMotion) {
    return (
      <Layout>
        <section className="py-20 md:py-28 hero-gradient">
          <div className="container mx-auto px-4 md:px-6">
            <h1 className="font-display text-4xl md:text-5xl font-bold text-center mb-16">
              Roadmap
            </h1>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {ROADMAP_PHASES.map((phase) => (
                <RoadmapNode
                  key={phase.id}
                  phase={phase}
                  isActive={true}
                  progress={1}
                />
              ))}
            </div>
          </div>
        </section>
      </Layout>
    );
  }

  return (
    <Layout>
      {/* 
         Height must be sufficient to allow continuous scrolling.
         We don't actually loop the DOM, we loop the visual transform.
      */}
      <div ref={containerRef} className="relative h-[5000vh]">

        {/* Fixed Viewport */}
        <div className="sticky top-0 h-screen w-full overflow-hidden flex flex-col justify-center items-center bg-background">

          {/* Background & Title */}
          <div className="absolute inset-0 hero-gradient opacity-20 pointer-events-none" />
          <div className="absolute top-12 left-0 right-0 text-center z-10">
            <h1 className="font-display text-3xl md:text-5xl font-bold mb-2">
              Roadmap
            </h1>
            <p className="text-muted-foreground text-sm uppercase tracking-widest">
              Phase {activePhase + 1} / {ROADMAP_PHASES.length}
            </p>
          </div>

          {/* The Lane Container */}
          <div className="relative w-full max-w-6xl h-[60vh] flex items-center justify-center perspective-1000">
            {ROADMAP_PHASES.map((phase, index) => (
              <CircularPhaseItem
                key={phase.id}
                phase={phase}
                index={index}
                total={ROADMAP_PHASES.length}
                scrollProgress={smoothProgress}
              />
            ))}
          </div>

          {/* Scroll Hint */}
          <div className="absolute bottom-12 text-center text-muted-foreground text-xs uppercase tracking-widest">
            Scroll to Explore
          </div>

        </div>
      </div>
    </Layout>
  );
}

function CircularPhaseItem({
  phase,
  index,
  total,
  scrollProgress
}: {
  phase: typeof ROADMAP_PHASES[number];
  index: number;
  total: number;
  scrollProgress: any;
}) {
  // We need to compute the position of THIS node relative to the "virtual head"
  // The virtual head moves from 0 -> infinity based on scroll
  // position = (index - virtualHead) modulo total

  const xParams = useTransform(scrollProgress, (value: number) => {
    // Arbitrary multiplier to speed up scroll through phases. 
    // 50 means we go through 50 phases in the full scroll height
    const virtualHead = value * 50;

    // Circular distance logic
    // We want the node to be at 0 when virtualHead is roughly equal to index
    let offset = ((index - virtualHead) % total);

    // Handle negative modulo result in JS
    if (offset < -total / 2) offset += total;
    if (offset > total / 2) offset -= total;

    // Now offset is between -total/2 and +total/2
    // We only care about visible range, say -1.5 to 1.5
    return offset;
  });

  // Map the offset to visual properties
  // Offset 0 = Center
  // Offset 1 = Right neighbor
  // Offset -1 = Left neighbor

  const x = useTransform(xParams, (offset) => {
    // Map -2..2 to pixel values
    // Using percentages or vw/vh is safer for responsiveness
    // Center is 0px
    return `${offset * 60}%`;
  });

  const scale = useTransform(xParams, [-2, -1, 0, 1, 2], [0.6, 0.8, 1.1, 0.8, 0.6]);
  const opacity = useTransform(xParams, [-1.5, -0.5, 0, 0.5, 1.5], [0, 1, 1, 1, 0]);
  const zIndex = useTransform(xParams, (offset) => {
    return Math.round(100 - Math.abs(offset) * 10);
  });
  const blur = useTransform(xParams, [-1, 0, 1], ["4px", "0px", "4px"]);

  // We only render if within visible range to save resources? 
  // CSS opacity handles visibility, but Framer Motion is efficient enough for 10 items.

  return (
    <motion.div
      style={{
        x,
        scale,
        opacity,
        zIndex,
        filter: useTransform(blur, b => `blur(${b})`),
        position: "absolute",
        width: "100%",
        maxWidth: "400px", // Card width
      }}
      className="will-change-transform"
    >
      <RoadmapNode
        phase={phase}
        isActive={true} // Visual state handled by transforms
        progress={1}
      />
    </motion.div>
  );
}
