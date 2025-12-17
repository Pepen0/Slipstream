import { motion } from "framer-motion";
import { Layout } from "@/components/layout/Layout";
import { TeamCard } from "@/components/TeamCard";
import { siteConfig } from "@/config/site";

export default function Team() {
  return (
    <Layout>
      {/* Hero */}
      <section className="py-20 md:py-28 hero-gradient">
        <div className="container mx-auto px-4 md:px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="max-w-3xl mx-auto text-center"
          >
            <h1 className="font-display text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-6">
              The Team
            </h1>
            <p className="text-lg text-muted-foreground max-w-xl mx-auto">
              A small crew of engineers and designers obsessed with making racing accessible.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Team Grid */}
      <section className="py-16 md:py-24 section-gradient">
        <div className="container mx-auto px-4 md:px-6">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 md:gap-8 max-w-5xl mx-auto">
            {siteConfig.team.map((member, index) => (
              <TeamCard key={member.name} member={member} index={index} />
            ))}
          </div>
        </div>
      </section>

      {/* Mission */}
      <section className="py-16 md:py-24 bg-card/30">
        <div className="container mx-auto px-4 md:px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="max-w-2xl mx-auto text-center"
          >
            <h2 className="font-display text-2xl md:text-3xl font-bold text-foreground mb-6">
              Our Mission
            </h2>
            <p className="text-muted-foreground leading-relaxed">
              We believe motion simulation shouldn't be a luxury. Slipstream is our answer to 
              overpriced, overcomplicated hardware. We're building something real drivers can 
              actually afford—without sacrificing the feel of the track.
            </p>
          </motion.div>
        </div>
      </section>
    </Layout>
  );
}
