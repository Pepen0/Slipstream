import { useRef, useEffect, useState } from "react";
import { motion, useScroll, useTransform, useReducedMotion } from "framer-motion";
import { Layout } from "@/components/layout/Layout";
import { RoadmapNode } from "@/components/RoadmapNode";
import { siteConfig } from "@/config/site";

export default function Roadmap() {
  const containerRef = useRef<HTMLDivElement>(null);
  const prefersReducedMotion = useReducedMotion();
  const [activePhase, setActivePhase] = useState(0);

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  });

  // Transform scroll progress to scale (zoom effect)
  const scale = useTransform(scrollYProgress, [0, 1], [0.5, 1.2]);
  const opacity = useTransform(scrollYProgress, [0, 0.1], [0, 1]);

  // Calculate which phase is active based on scroll
  useEffect(() => {
    const unsubscribe = scrollYProgress.on("change", (value) => {
      const phaseCount = siteConfig.roadmap.length;
      const phaseIndex = Math.min(
        Math.floor(value * phaseCount),
        phaseCount - 1
      );
      setActivePhase(phaseIndex);
    });

    return () => unsubscribe();
  }, [scrollYProgress]);

  // For reduced motion, show a simple static layout
  if (prefersReducedMotion) {
    return (
      <Layout>
        <section className="py-20 md:py-28 hero-gradient">
          <div className="container mx-auto px-4 md:px-6">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="max-w-3xl mx-auto text-center mb-16"
            >
              <h1 className="font-display text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-6">
                Roadmap
              </h1>
              <p className="text-lg text-muted-foreground">
                From concept to launch—our journey building Slipstream.
              </p>
            </motion.div>

            <div className="max-w-2xl mx-auto space-y-8">
              {siteConfig.roadmap.map((phase, index) => (
                <motion.div
                  key={phase.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <RoadmapNode phase={phase} isActive={true} progress={1} />
                </motion.div>
              ))}
            </div>
          </div>
        </section>
      </Layout>
    );
  }

  return (
    <Layout>
      {/* Scrollable container */}
      <div ref={containerRef} className="relative" style={{ height: "400vh" }}>
        {/* Sticky viewport */}
        <div className="sticky top-20 h-[calc(100vh-80px)] overflow-hidden">
          {/* Background */}
          <div className="absolute inset-0 hero-gradient" />
          
          {/* Glow effect */}
          <motion.div
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full"
            style={{
              background: "radial-gradient(circle, hsl(0 85% 55% / 0.1) 0%, transparent 70%)",
              scale,
            }}
          />

          {/* Header */}
          <motion.div
            style={{ opacity }}
            className="absolute top-8 left-1/2 -translate-x-1/2 text-center z-10 w-full px-4"
          >
            <h1 className="font-display text-4xl md:text-5xl font-bold text-foreground mb-2">
              Roadmap
            </h1>
            <p className="text-sm md:text-base text-muted-foreground">
              From concept to launch—scroll to explore our journey
            </p>
          </motion.div>

          {/* Progress indicator */}
          <div className="absolute right-8 top-1/2 -translate-y-1/2 flex flex-col gap-2 z-10">
            {siteConfig.roadmap.map((_, index) => (
              <motion.div
                key={index}
                className="w-2 h-8 rounded-full bg-border overflow-hidden"
              >
                <motion.div
                  className="w-full bg-primary"
                  style={{
                    height: index < activePhase ? "100%" : index === activePhase ? "50%" : "0%",
                  }}
                  transition={{ duration: 0.3 }}
                />
              </motion.div>
            ))}
          </div>

          {/* Roadmap content */}
          <motion.div
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-4xl px-4"
            style={{ scale }}
          >
            <div className="grid grid-cols-1 gap-6">
              {siteConfig.roadmap.map((phase, index) => {
                // Calculate individual phase progress
                const phaseStart = index / siteConfig.roadmap.length;
                const phaseEnd = (index + 1) / siteConfig.roadmap.length;
                
                return (
                  <PhaseWrapper
                    key={phase.id}
                    phase={phase}
                    index={index}
                    activePhase={activePhase}
                    scrollProgress={scrollYProgress}
                    phaseStart={phaseStart}
                    phaseEnd={phaseEnd}
                  />
                );
              })}
            </div>
          </motion.div>

          {/* Scroll hint */}
          <motion.div
            className="absolute bottom-8 left-1/2 -translate-x-1/2 text-center"
            style={{ opacity: useTransform(scrollYProgress, [0, 0.2], [1, 0]) }}
          >
            <p className="text-xs text-muted-foreground font-display uppercase tracking-wider">
              Scroll to zoom
            </p>
            <motion.div
              animate={{ y: [0, 5, 0] }}
              transition={{ duration: 1.5, repeat: Infinity }}
              className="mt-2"
            >
              <div className="w-4 h-8 mx-auto rounded-full border-2 border-muted-foreground/30 flex items-start justify-center pt-2">
                <div className="w-1 h-2 rounded-full bg-muted-foreground" />
              </div>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </Layout>
  );
}

// Separate component for phase to handle individual transforms
function PhaseWrapper({
  phase,
  index,
  activePhase,
  scrollProgress,
  phaseStart,
  phaseEnd,
}: {
  phase: typeof siteConfig.roadmap[number];
  index: number;
  activePhase: number;
  scrollProgress: any;
  phaseStart: number;
  phaseEnd: number;
}) {
  const phaseProgress = useTransform(
    scrollProgress,
    [phaseStart, phaseEnd],
    [0, 1]
  );

  const y = useTransform(phaseProgress, [0, 1], [50, 0]);
  const itemOpacity = useTransform(
    scrollProgress,
    [
      Math.max(0, phaseStart - 0.1),
      phaseStart,
      phaseEnd,
      Math.min(1, phaseEnd + 0.1),
    ],
    [0.2, 1, 1, 0.2]
  );

  return (
    <motion.div
      style={{
        y: index === activePhase ? y : 0,
        opacity: itemOpacity,
      }}
      className={index === activePhase ? "z-10" : "z-0"}
    >
      <RoadmapNode
        phase={phase}
        isActive={index === activePhase}
        progress={index <= activePhase ? 1 : 0}
      />
    </motion.div>
  );
}
