import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { Menu, X, Instagram, Youtube } from "lucide-react";
import { Button } from "@/components/ui/button";
import { siteConfig } from "@/config/site";
import { cn } from "@/lib/utils";

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();

  const isActive = (href: string) => location.pathname === href;

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md border-b border-border/50">
      <div className="container mx-auto px-4 md:px-6">
        <nav className="flex items-center justify-between h-16 md:h-20">
          {/* Logo */}
          <Link
            to="/"
            title="Slipstream Home"
          >
            <img src="/logo-slipstream.svg" alt="Slipstream" className="h-12 md:h-24 w-auto" />
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-8">
            {siteConfig.nav.main.map((item) => (
              <Link
                key={item.href}
                to={item.href}
                className={cn(
                  "font-display text-sm uppercase tracking-wider transition-colors",
                  isActive(item.href)
                    ? "text-foreground"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                {item.label}
              </Link>
            ))}
            <Button variant="hero" size="default" asChild>
              <Link to="/waitlist">Join Waitlist</Link>
            </Button>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="md:hidden p-2 text-foreground"
            onClick={() => setMobileMenuOpen(true)}
            aria-label="Open menu"
          >
            <Menu className="w-6 h-6" />
          </button>
        </nav>
      </div>

      {/* Mobile Menu Overlay */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-background md:hidden"
          >
            <div className="flex flex-col h-full p-6">
              {/* Close Button */}
              <div className="flex justify-between items-center mb-12">
                <img src="/logo-slipstream.svg" alt="Slipstream" className="h-12 w-auto" />
                <button
                  onClick={() => setMobileMenuOpen(false)}
                  className="p-2 text-foreground"
                  aria-label="Close menu"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              {/* Mobile Links */}
              <nav className="flex flex-col gap-6 flex-1">
                <Link
                  to="/"
                  onClick={() => setMobileMenuOpen(false)}
                  className={cn(
                    "font-display text-2xl uppercase tracking-wider transition-colors",
                    isActive("/") ? "text-foreground" : "text-muted-foreground"
                  )}
                >
                  Home
                </Link>
                {siteConfig.nav.main.map((item) => (
                  <Link
                    key={item.href}
                    to={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className={cn(
                      "font-display text-2xl uppercase tracking-wider transition-colors",
                      isActive(item.href) ? "text-foreground" : "text-muted-foreground"
                    )}
                  >
                    {item.label}
                  </Link>
                ))}
                <Link
                  to="/waitlist"
                  onClick={() => setMobileMenuOpen(false)}
                  className={cn(
                    "font-display text-2xl uppercase tracking-wider transition-colors",
                    isActive("/waitlist") ? "text-foreground" : "text-muted-foreground"
                  )}
                >
                  Waitlist
                </Link>
              </nav>

              {/* Socials */}
              <div className="flex gap-6 pt-8 border-t border-border">
                <a
                  href={siteConfig.socials.instagram}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted-foreground hover:text-foreground transition-colors"
                >
                  <motion.span
                    className="inline-flex"
                    whileHover={{ rotate: 360 }}
                    transition={{ duration: 0.6, ease: "linear", repeat: Infinity }}
                  >
                    <Instagram className="w-6 h-6" />
                  </motion.span>
                </a>
                <a
                  href={siteConfig.socials.youtube}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted-foreground hover:text-foreground transition-colors"
                >
                  <motion.span
                    className="inline-flex"
                    whileHover={{ rotate: 360 }}
                    transition={{ duration: 0.6, ease: "linear", repeat: Infinity }}
                  >
                    <Youtube className="w-6 h-6" />
                  </motion.span>
                </a>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header >
  );
}
