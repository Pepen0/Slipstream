import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft } from "lucide-react";
import { Layout } from "@/components/layout/Layout";
import { WaitlistForm } from "@/components/WaitlistForm";
import { siteConfig } from "@/config/site";

export default function Waitlist() {
  return (
    <Layout>
      <section className="min-h-[calc(100vh-200px)] flex items-center py-20 md:py-28 hero-gradient">
        <div className="container mx-auto px-4 md:px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="max-w-xl mx-auto"
          >
            {/* Back link */}
            <Link
              to="/"
              className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors mb-8"
            >
              <ArrowLeft className="w-4 h-4" />
              Back to home
            </Link>

            {/* Card */}
            <div className="card-glass rounded-2xl p-8 md:p-10">
              <div className="text-center mb-8">
                <h1 className="font-display text-3xl md:text-4xl font-bold text-foreground mb-4">
                  Join the Slipstream Waitlist
                </h1>
                <p className="text-muted-foreground leading-relaxed">
                  Get updates on launch, live demos, and early access opportunities. 
                  Be the first to experience the future of accessible motion simulation.
                </p>
              </div>

              <WaitlistForm source="waitlist-page" showFullForm={true} />

              {/* Social links */}
              <div className="mt-8 pt-8 border-t border-border">
                <p className="text-center text-sm text-muted-foreground mb-4">
                  Follow us for the latest updates
                </p>
                <div className="flex justify-center gap-4">
                  <a
                    href={siteConfig.socials.instagram}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-4 py-2 rounded-lg bg-secondary hover:bg-accent text-sm font-display uppercase tracking-wider transition-colors"
                  >
                    Instagram
                  </a>
                  <a
                    href={siteConfig.socials.youtube}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-4 py-2 rounded-lg bg-secondary hover:bg-accent text-sm font-display uppercase tracking-wider transition-colors"
                  >
                    YouTube
                  </a>
                </div>
              </div>
            </div>

            {/* Trust indicators */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
              className="mt-8 text-center"
            >
              <p className="text-xs text-muted-foreground">
                We respect your privacy. No spam, ever.
              </p>
            </motion.div>
          </motion.div>
        </div>
      </section>
    </Layout>
  );
}
