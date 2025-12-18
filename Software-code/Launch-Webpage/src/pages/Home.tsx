import { Link } from "react-router-dom";
import { motion, useReducedMotion } from "framer-motion";
import { ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Layout } from "@/components/layout/Layout";
import { Countdown } from "@/components/Countdown";
import { SimulatorModel } from "@/components/SimulatorModel";
import { WaitlistForm } from "@/components/WaitlistForm";

const fadeUpVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: (delay: number) => ({
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, delay, ease: "easeOut" },
  }),
};

export default function Home() {
  const prefersReducedMotion = useReducedMotion();

  const scrollToContent = () => {
    const problemSection = document.getElementById("problem");
    if (problemSection) {
      problemSection.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <Layout>
      {/* Hero Section */}
      <section className="relative min-h-[calc(100vh-80px)] flex items-center overflow-hidden hero-gradient py-12 md:py-20">
        {/* Background Radial Gradient - subtle focus on center (kept for vibe) */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: 'radial-gradient(circle at 50% 50%, rgba(20, 20, 20, 1) 0%, rgba(5, 5, 5, 1) 100%)'
          }}
        />

        <div className="container mx-auto px-4 md:px-6 relative z-10 h-full">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-8 items-center h-full">

            {/* LEFT COLUMN: Text Content */}
            <div className="text-center lg:text-left space-y-8 order-1 lg:order-1">
              <motion.h1
                variants={fadeUpVariants}
                initial="hidden"
                animate="visible"
                custom={0.2}
                className="font-display text-5xl md:text-7xl lg:text-8xl font-bold tracking-tight text-foreground"
              >
                SLIPSTREAM
              </motion.h1>

              <motion.p
                variants={fadeUpVariants}
                initial="hidden"
                animate="visible"
                custom={0.4}
                className="max-w-2xl mx-auto lg:mx-0 text-lg md:text-xl text-muted-foreground leading-relaxed"
              >
                "Nobody should have to choose between a new Honda Civic or a racing simulator."
              </motion.p>

              {/* Countdown */}
              <motion.div
                variants={fadeUpVariants}
                initial="hidden"
                animate="visible"
                custom={0.6}
                className="pt-2"
              >
                <div className="flex justify-center lg:justify-start">
                  <Countdown />
                </div>
              </motion.div>

              {/* CTAs */}
              <motion.div
                variants={fadeUpVariants}
                initial="hidden"
                animate="visible"
                custom={0.8}
                className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4 pt-4"
              >
                <Button variant="hero" size="xl" asChild>
                  <Link to="/waitlist">Join the Waitlist</Link>
                </Button>
                <Button variant="heroOutline" size="xl" onClick={scrollToContent}>
                  Explore the Simulator
                </Button>
              </motion.div>
            </div>

            {/* RIGHT COLUMN: 3D Model */}
            <div className="relative order-2 lg:order-2 w-full h-[50vh] lg:h-[800px] flex items-center justify-center">
              {/* Red Glow Accent - Behind Rig (Localized) */}
              <div
                className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[120%] h-[120%] z-0 pointer-events-none"
                style={{
                  background: 'radial-gradient(circle, rgba(229, 57, 53, 0.1) 0%, transparent 70%)',
                  filter: 'blur(80px)'
                }}
              />

              <div className="w-full h-full relative z-10">
                <SimulatorModel />
              </div>
            </div>

          </div>

          {/* Scroll indicator */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.2 }}
            className="absolute bottom-8 left-1/2 -translate-x-1/2 lg:left-8 lg:translate-x-0"
          >
            <button
              onClick={scrollToContent}
              className="p-2 text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Scroll to content"
            >
              <motion.div
                animate={prefersReducedMotion ? {} : { y: [0, 8, 0] }}
                transition={{ duration: 1.5, repeat: Infinity }}
              >
                <ChevronDown className="w-6 h-6" />
              </motion.div>
            </button>
          </motion.div>
        </div>
      </section>

      {/* Problem Section */}
      <section id="problem" className="py-20 md:py-32 section-gradient">
        <div className="container mx-auto px-4 md:px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="max-w-3xl mx-auto text-center"
          >
            <span className="inline-block px-4 py-1.5 rounded-full bg-destructive/10 text-destructive font-display text-xs uppercase tracking-wider mb-6">
              The Problem
            </span>

            <h2 className="font-display text-3xl md:text-4xl lg:text-5xl font-bold text-foreground mb-8 leading-tight">
              "Nobody should have to choose between a new Honda Civic or a racing simulator."
            </h2>

            <ul className="space-y-4 text-left max-w-xl mx-auto">
              {[
                "Motion simulators routinely exceed $10,000",
                "Heavy mechanical systems limit where they can be used",
                "Overkill for hobbyists and entry-level drivers",
              ].map((item, index) => (
                <motion.li
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.4, delay: index * 0.1 }}
                  className="flex items-start gap-3"
                >
                  <span className="w-1.5 h-1.5 mt-2.5 rounded-full bg-primary shrink-0" />
                  <span className="text-muted-foreground">{item}</span>
                </motion.li>
              ))}
            </ul>
          </motion.div>
        </div>
      </section>

      {/* Solution Section */}
      <section className="py-20 md:py-32 bg-card/30">
        <div className="container mx-auto px-4 md:px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="max-w-4xl mx-auto"
          >
            <div className="text-center mb-12">
              <span className="inline-block px-4 py-1.5 rounded-full bg-primary/10 text-primary font-display text-xs uppercase tracking-wider mb-6">
                The Alternative
              </span>

              <h2 className="font-display text-3xl md:text-4xl lg:text-5xl font-bold text-foreground mb-6">
                Built Different
              </h2>

              <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
                Compact. Control-driven. Designed for intro racing & hobbyist use.
              </p>
            </div>

            {/* Features Grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-12">
              {[
                {
                  title: "Motion Realism",
                  description: "2-DOF actuation delivers convincing motion feedback for immersive racing.",
                },
                {
                  title: "Low Footprint",
                  description: "Compact design fits in apartments, offices, and small spaces.",
                },
                {
                  title: "Firmware-Driven",
                  description: "Precision control algorithms tuned for realistic force response.",
                },
              ].map((feature, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                  className="card-glass rounded-xl p-6 text-center racing-stripe"
                >
                  <h3 className="font-display text-lg font-semibold text-foreground mb-2">
                    {feature.title}
                  </h3>
                  <p className="text-sm text-muted-foreground">
                    {feature.description}
                  </p>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </section>

      {/* Countdown Repeat */}
      <section className="py-20 md:py-28 hero-gradient">
        <div className="container mx-auto px-4 md:px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="max-w-2xl mx-auto text-center"
          >
            <h2 className="font-display text-2xl md:text-3xl font-bold text-foreground mb-8">
              Launching Soon
            </h2>
            <Countdown />
          </motion.div>
        </div>
      </section>

      {/* Inline Waitlist Section */}
      <section className="py-20 md:py-32 section-gradient">
        <div className="container mx-auto px-4 md:px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="max-w-xl mx-auto"
          >
            <div className="card-glass rounded-2xl p-8 md:p-10">
              <div className="text-center mb-6">
                <h2 className="font-display text-2xl md:text-3xl font-bold text-foreground mb-2">
                  Be First In Line
                </h2>
                <p className="text-muted-foreground">
                  Be the first to know when Slipstream launches.
                </p>
              </div>

              <WaitlistForm source="home-inline" />

              <div className="mt-6 text-center">
                <Link
                  to="/waitlist"
                  className="text-sm text-muted-foreground hover:text-foreground transition-colors underline underline-offset-4"
                >
                  See full waitlist details →
                </Link>
              </div>
            </div>
          </motion.div>
        </div>
      </section>
    </Layout>
  );
}
