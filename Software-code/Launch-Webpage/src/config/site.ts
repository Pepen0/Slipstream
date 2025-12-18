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
    instagram: "https://www.instagram.com/slipstrearn",
    youtube: "https://www.youtube.com/channel/UCHCf9AAipaBe-YrR8mLdMkw",
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
      name: "Ammar Sathar",
      role: "Founder & CTO",
      bio: "The mastermind with the plan behind the Slipstream project.",
    },
    {
      name: "Penoelo Thibeaud",
      role: "Founder & CEO",
      bio: "Keeps everything running smooth, start to finish.",
    },
    {
      name: "Anthony Aldama",
      role: "Chief Electrical Designer",
      bio: "Designs the circuits that power it all.",
    },
    {
      name: "Usman Shehu Usman",
      role: "Co-Founder & Electrical Designer",
      bio: "Makes sure the hardware stays sharp and steady.",
    },
    {
      name: "Rahul Patel",
      role: "Founding Integration Designer",
      bio: "Connects the motion system to the sim brain.",
    },
    {
      name: "Olivier Dupre",
      role: "Founding Electrical Designer",
      bio: "Keeps the power flowing no matter what.",
    },
  ],
};

export type RoadmapPhase = typeof siteConfig.roadmap[number];
export type TeamMember = typeof siteConfig.team[number];
