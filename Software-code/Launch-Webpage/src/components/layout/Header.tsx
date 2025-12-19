import { useState, useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { Menu, X, Instagram, Youtube } from "lucide-react";
import { Button } from "@/components/ui/button";
import { siteConfig } from "@/config/site";
import { cn } from "@/lib/utils";

const overlayVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { duration: 0.25, ease: "easeOut" },
  },
  exit: {
    opacity: 0,
    transition: { duration: 0.2, ease: "easeIn" },
  },
};

const panelVariants = {
  hidden: { opacity: 0, y: -24 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      type: "spring",
      stiffness: 260,
      damping: 28,
      delayChildren: 0.05,
      staggerChildren: 0.04,
    },
  },
  exit: {
    opacity: 0,
    y: -12,
    transition: { duration: 0.2, ease: "easeInOut" },
  },
};

const linkVariants = {
  hidden: { opacity: 0, y: 8 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.2, ease: "easeOut" },
  },
};

const socialsVariants = {
  hidden: { opacity: 0, y: 12 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.25, ease: "easeOut" },
  },
};

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();

  const isActive = (href: string) => location.pathname === href;

  // Scroll lock when mobile menu is open
  useEffect(() => {
    if (mobileMenuOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [mobileMenuOpen]);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/95 backdrop-blur-md border-b border-white/5">
      <div className="container mx-auto px-4 md:px-6">
        <nav className="flex items-center justify-between h-16 md:h-20">
          {/* Logo */}
          <Link to="/" title="Slipstream Home" className="flex items-center">
            <motion.img
              src="/logo-slipstream.svg"
              alt="Slipstream"
              className="h-20 md:h-40 w-auto"
              initial={{ opacity: 0, y: -6 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.25, ease: "easeOut" }}
            />
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-8">
            {siteConfig.nav.main.map((item) => (
              <motion.div
                key={item.href}
                initial={{ opacity: 0, y: -6 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.2, ease: "easeOut" }}
              >
                <Link
                  to={item.href}
                  className={cn(
                    "font-display text-sm uppercase tracking-[0.18em] transition-colors duration-200",
                    isActive(item.href)
                      ? "text-white"
                      : "text-white/60 hover:text-white"
                  )}
                >
                  {item.label}
                </Link>
              </motion.div>
            ))}
            <motion.div
              initial={{ opacity: 0, y: -6 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.2, ease: "easeOut" }}
            >
              <Button variant="hero" size="default" asChild>
                <Link to="/waitlist" className="tracking-[0.18em] uppercase">
                  Join Waitlist
                </Link>
              </Button>
            </motion.div>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="md:hidden p-2 text-white"
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
            variants={overlayVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
            className="fixed inset-0 z-50 bg-black/80 backdrop-blur-xl md:hidden"
          >
            <motion.div
              variants={panelVariants}
              initial="hidden"
              animate="visible"
              exit="exit"
              className="flex h-full flex-col px-6 pt-6 pb-8 bg-gradient-to-b from-[#D7171F] via-[#160000] to-black"
            >
              {/* Top bar */}
              <div className="flex items-center justify-between mb-10">
                <img
                  src="/logo-slipstream.svg"
                  alt="Slipstream"
                  className="h-10 w-auto drop-shadow-[0_0_16px_rgba(0,0,0,0.45)]"
                />
                <motion.button
                  onClick={() => setMobileMenuOpen(false)}
                  className="inline-flex items-center justify-center rounded-full border border-white/20 bg-black/40 p-3 backdrop-blur text-white"
                  aria-label="Close menu"
                  whileHover={{ scale: 1.08, opacity: 1 }}
                  whileTap={{ scale: 0.96 }}
                  transition={{ type: "spring", stiffness: 260, damping: 18 }}
                >
                  <X className="w-5 h-5" />
                </motion.button>
              </div>

              {/* Mobile Links – big “bubble” panel */}
              <nav className="flex-1 flex items-center">
                <motion.div
                  className="w-full rounded-[32px] border border-white/20 bg-gradient-to-b from-[#FF3838]/85 via-[#D7171F]/90 to-[#5A0508]/90 backdrop-blur-xl px-7 py-10 space-y-5 shadow-[0_18px_60px_rgba(0,0,0,0.7)] relative overflow-hidden"
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 8 }}
                  transition={{ duration: 0.25, ease: "easeOut", delay: 0.05 }}
                  whileHover={{ scale: 1.01 }}
                  whileTap={{ scale: 0.99 }}
                >
                  {/* subtle highlights */}
                  <div className="absolute inset-x-6 top-0 h-24 bg-white/5 blur-2xl pointer-events-none" />
                  <div className="absolute -right-16 bottom-0 w-48 h-48 rounded-full bg-white/6 blur-3xl pointer-events-none" />

                  <div className="h-[3px] w-16 rounded-full bg-gradient-to-r from-white via-white/70 to-white/0 mb-4" />

                  <motion.div
                    variants={linkVariants}
                    whileHover={{ x: 6, opacity: 1 }}
                    className="border-b border-white/18 pb-3"
                  >
                    <Link
                      to="/"
                      onClick={() => setMobileMenuOpen(false)}
                      className={cn(
                        "font-display text-3xl uppercase tracking-[0.25em] transition-colors",
                        isActive("/")
                          ? "text-white"
                          : "text-white/80 hover:text-white"
                      )}
                    >
                      Home
                    </Link>
                  </motion.div>

                  {siteConfig.nav.main.map((item) => (
                    <motion.div
                      key={item.href}
                      variants={linkVariants}
                      whileHover={{ x: 6, opacity: 1 }}
                      className="pb-3 border-b border-white/18"
                    >
                      <Link
                        to={item.href}
                        onClick={() => setMobileMenuOpen(false)}
                        className={cn(
                          "font-display text-3xl uppercase tracking-[0.25em] transition-colors",
                          isActive(item.href)
                            ? "text-white"
                            : "text-white/80 hover:text-white"
                        )}
                      >
                        {item.label}
                      </Link>
                    </motion.div>
                  ))}

                  <motion.div
                    variants={linkVariants}
                    whileHover={{ x: 6, opacity: 1 }}
                    className="pt-1"
                  >
                    <Link
                      to="/waitlist"
                      onClick={() => setMobileMenuOpen(false)}
                      className={cn(
                        "font-display text-3xl uppercase tracking-[0.25em] transition-colors",
                        isActive("/waitlist")
                          ? "text-white"
                          : "text-white/80 hover:text-white"
                      )}
                    >
                      Waitlist
                    </Link>
                  </motion.div>
                </motion.div>
              </nav>

              {/* Socials */}
              <motion.div
                variants={socialsVariants}
                className="flex items-center gap-6 pt-6 border-t border-white/10"
              >
                <a
                  href={siteConfig.socials.instagram}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-white/70 hover:text-white transition-colors"
                >
                  <motion.span
                    className="inline-flex items-center justify-center rounded-full border border-white/20 bg-black/40 p-3 backdrop-blur"
                    whileHover={{ scale: 1.08, opacity: 1 }}
                    whileTap={{ scale: 0.96 }}
                    transition={{ type: "spring", stiffness: 260, damping: 18 }}
                  >
                    <Instagram className="w-5 h-5" />
                  </motion.span>
                </a>
                <a
                  href={siteConfig.socials.youtube}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-white/70 hover:text-white transition-colors"
                >
                  <motion.span
                    className="inline-flex items-center justify-center rounded-full border border-white/20 bg-black/40 p-3 backdrop-blur"
                    whileHover={{ scale: 1.08, opacity: 1 }}
                    whileTap={{ scale: 0.96 }}
                    transition={{ type: "spring", stiffness: 260, damping: 18 }}
                  >
                    <Youtube className="w-5 h-5" />
                  </motion.span>
                </a>
              </motion.div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </header >
  );
}
