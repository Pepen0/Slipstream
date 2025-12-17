export const siteConfig = {
  name: "Slipstream",
  tagline: "Built for the drivers who can't stop thinking about the next lap.",
  description: "Compact 2-DOF motion simulator for intro-to-racing drivers and hobbyists.",
  
  // Launch configuration
  launch: {
    date: "2026-04-01T00:00:00Z", // April 1st, 2026
    liveMessage: "We're live.",
  },
  
  // Event details for launch email
  event: {
    location: "Concordia University",
    address: "1455 De Maisonneuve Blvd. W, Montreal, QC",
    date: "April 2025",
    time: "TBA",
  },
  
  // Social links
  socials: {
    instagram: "https://instagram.com/slipstream",
    youtube: "https://youtube.com/@slipstream",
  },
  
  // Navigation
  nav: {
    main: [
      { label: "Team", href: "/team" },
      { label: "Roadmap", href: "/roadmap" },
    ],
    footer: [
      { label: "Home", href: "/" },
      { label: "Team", href: "/team" },
      { label: "Roadmap", href: "/roadmap" },
      { label: "Waitlist", href: "/waitlist" },
    ],
  },
  
  // Roadmap phases
  roadmap: [
    {
      id: 1,
      title: "Concept & Control Design",
      description: "Defining the motion control architecture and system requirements.",
      status: "completed" as const,
    },
    {
      id: 2,
      title: "Prototype Build",
      description: "Manufacturing the first physical prototype with 2-DOF actuation.",
      status: "completed" as const,
    },
    {
      id: 3,
      title: "Firmware Refinement",
      description: "Optimizing control algorithms for realistic motion feedback.",
      status: "in-progress" as const,
    },
    {
      id: 4,
      title: "Simulator Integration",
      description: "Connecting with popular racing simulation software.",
      status: "planned" as const,
    },
    {
      id: 5,
      title: "Launch",
      description: "Public release and live demonstrations.",
      status: "planned" as const,
    },
  ],
  
  // Team members
  team: [
    {
      name: "Alex Chen",
      role: "Lead Engineer",
      bio: "Mechanical engineer with a passion for motorsport and control systems.",
      image: "/team/alex.jpg",
    },
    {
      name: "Sarah Martinez",
      role: "Firmware Developer",
      bio: "Embedded systems specialist focused on real-time motion control.",
      image: "/team/sarah.jpg",
    },
    {
      name: "James Wilson",
      role: "Product Designer",
      bio: "Industrial designer bringing ergonomics and aesthetics to racing hardware.",
      image: "/team/james.jpg",
    },
    {
      name: "Emily Park",
      role: "Operations Lead",
      bio: "Making sure everything runs smoothly from prototype to production.",
      image: "/team/emily.jpg",
    },
  ],
};

export type RoadmapPhase = typeof siteConfig.roadmap[number];
export type TeamMember = typeof siteConfig.team[number];
