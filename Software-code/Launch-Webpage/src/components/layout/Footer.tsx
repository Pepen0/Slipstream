import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { Instagram, Youtube } from "lucide-react";
import { siteConfig } from "@/config/site";

export function Footer() {
  return (
    <footer className="border-t border-border bg-card/50">
      <div className="container mx-auto px-4 md:px-6 py-12 md:py-16">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-12">
          {/* Brand */}
          <div className="space-y-4">
            <Link to="/" className="font-display text-xl font-bold tracking-wider">
              SLIPSTREAM
            </Link>
            <p className="text-muted-foreground text-sm max-w-xs">
              {siteConfig.tagline}
            </p>
          </div>

          {/* Navigation */}
          <div className="space-y-4">
            <h4 className="font-display text-sm uppercase tracking-wider text-muted-foreground">
              Navigation
            </h4>
            <nav className="flex flex-col gap-2">
              {siteConfig.nav.footer.map((item) => (
                <Link
                  key={item.href}
                  to={item.href}
                  className="text-sm text-foreground/70 hover:text-foreground transition-colors"
                >
                  {item.label}
                </Link>
              ))}
            </nav>
          </div>

          {/* Socials */}
          <div className="space-y-4">
            <h4 className="font-display text-sm uppercase tracking-wider text-muted-foreground">
              Follow Us
            </h4>
            <div className="flex gap-4">
              <a
                href={siteConfig.socials.instagram}
                target="_blank"
                rel="noopener noreferrer"
                className="p-2 rounded-md bg-secondary hover:bg-accent text-foreground/70 hover:text-foreground transition-all"
                aria-label="Follow on Instagram"
              >
                <motion.span
                  className="inline-flex"
                  whileHover={{ rotate: 360 }}
                  transition={{ duration: 0.6, ease: "linear", repeat: Infinity }}
                >
                  <Instagram className="w-5 h-5" />
                </motion.span>
              </a>
              <a
                href={siteConfig.socials.youtube}
                target="_blank"
                rel="noopener noreferrer"
                className="p-2 rounded-md bg-secondary hover:bg-accent text-foreground/70 hover:text-foreground transition-all"
                aria-label="Subscribe on YouTube"
              >
                <motion.span
                  className="inline-flex"
                  whileHover={{ rotate: 360 }}
                  transition={{ duration: 0.6, ease: "linear", repeat: Infinity }}
                >
                  <Youtube className="w-5 h-5" />
                </motion.span>
              </a>
            </div>
          </div>
        </div>

        {/* Copyright */}
        <div className="mt-12 pt-8 border-t border-border/50">
          <p className="text-xs text-muted-foreground text-center">
            © {new Date().getFullYear()} Slipstream. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
