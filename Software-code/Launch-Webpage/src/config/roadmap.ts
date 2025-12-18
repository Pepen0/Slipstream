export type RoadmapStatus = "completed" | "in-progress" | "planned";

export interface RoadmapPhase {
    id: number;
    title: string;
    description: string;
    progress: number; // 0-100
    image?: string;
}

export const ROADMAP_PHASES: RoadmapPhase[] = [
    {
        id: 1,
        title: "Project Planning & Requirements Definition",
        description: "Defining system specifications, motion profiles, and performance targets.",
        progress: 100,
        image: "/phases/Project-Planning-Requirements-Definition.png",
    },
    {
        id: 2,
        title: "Electronics Design and PCB",
        description: "Designing the custom motor controller and power distribution boards.",
        progress: 50,
        image: "/phases/Electronics-Design-and-PCB.png",
    },
    {
        id: 3,
        title: "Actuators and Sensors",
        description: "Selecting and integrating industrial-grade motors and encoders.",
        progress: 10,
        image: "/phases/Actuators-and-Sensors.jpg",
    },
    {
        id: 4,
        title: "Motion Control Firmware",
        description: "Developing real-time control loops for precise position and velocity control.",
        progress: 10,
        image: "/phases/Motion-Control-Firmware.png",
    },
    {
        id: 5,
        title: "PC Software and Telemetry Interface",
        description: "Building the desktop app to bridge game telemetry with the simulator.",
        progress: 45,
        image: "/phases/PC-Software-Telemetry-Interface.jpeg",
    },
    {
        id: 6,
        title: "Motion Cueing and Realistic Simulation",
        description: "Tuning motion algorithms to translate G-forces into realistic platform movement.",
        progress: 0,
        image: "/phases/Motion-Cueing-Realistic-Simulation.jpeg",
    },
    {
        id: 7,
        title: "Force Feedback Wheel",
        description: "Integrating high-fidelity force feedback for direct steering connection.",
        progress: 10,
        image: "/phases/Force-Feedback-Wheel.png",
    },
    {
        id: 8,
        title: "User Interface, Calibration & Final Integration",
        description: "Polishing the user experience and ensuring seamless hardware-software sync.",
        progress: 0,
        image: "/phases/User-Interface-Calibration-Final-Integration.JPG",
    },
    {
        id: 9,
        title: "Final Testing, Optimization & Documentation",
        description: "Rigorous stress testing and preparing detailed documentation for launch.",
        progress: 20,
        image: "/phases/Final-Testing-Optimization-Documentation.jpeg",
    },
    {
        id: 10,
        title: "Launch",
        description: "Public launch and first customer deployments.",
        progress: 5,
        image: "/phases/Launch.png",
    },
];
