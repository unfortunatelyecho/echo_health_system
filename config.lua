ECHO = {}

-- Framework Detection & Auto-Config
ECHO.Framework = "auto" -- auto, qbcore, esx, qbox, custom
ECHO.CoreName = "qb-core" -- Change based on your core resource name

-- Database Settings
ECHO.UseOXMySQL = true

-- Organ System Configuration
ECHO.Organs = {
    Enabled = true,
    
    Types = {
        { name = "heart", label = "Heart", compatibility = true, price = 50000, decay = 240 },
        { name = "kidney", label = "Kidney", compatibility = true, price = 35000, decay = 180 },
        { name = "liver", label = "Liver", compatibility = true, price = 40000, decay = 200 },
        { name = "lung", label = "Lung", compatibility = true, price = 38000, decay = 190 },
        { name = "cornea", label = "Cornea", compatibility = false, price = 15000, decay = 120 },
        { name = "pancreas", label = "Pancreas", compatibility = true, price = 32000, decay = 160 }
    },
    
    BloodTypes = { "O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-" },
    
    Compatibility = {
        ["O-"] = { "O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+" },
        ["O+"] = { "O+", "A+", "B+", "AB+" },
        ["A-"] = { "A-", "A+", "AB-", "AB+" },
        ["A+"] = { "A+", "AB+" },
        ["B-"] = { "B-", "B+", "AB-", "AB+" },
        ["B+"] = { "B+", "AB+" },
        ["AB-"] = { "AB-", "AB+" },
        ["AB+"] = { "AB+" }
    },
    
    DonationCooldown = 30, -- Days
    LegalDonationReward = 5000,
    BlackMarketMultiplier = 3.5,
    
    Locations = {
        Hospital = vector3(298.56, -584.45, 43.26),
        BlackMarket = vector3(707.89, -962.34, 30.41)
    }
}

-- Mental Health Configuration
ECHO.MentalHealth = {
    Enabled = true,
    
    StartingMental = 100,
    MinMental = 0,
    MaxMental = 100,
    
    TraumaEvents = {
        witnessDeadBody = { impact = -5, message = "You feel disturbed..." },
        witnessShootout = { impact = -8, message = "Your hands are shaking..." },
        witnessExplosion = { impact = -12, message = "Your ears are ringing..." },
        injuredSeverely = { impact = -15, message = "You're traumatized..." },
        witnessExecution = { impact = -20, message = "This image will haunt you..." },
        closeFriendDeath = { impact = -25, message = "You feel devastated..." }
    },
    
    PositiveEvents = {
        therapy = { impact = 20, cooldown = 3600 },
        meditation = { impact = 5, cooldown = 1800 },
        socializing = { impact = 3, cooldown = 300 },
        exercise = { impact = 4, cooldown = 3600 }
    },
    
    Stages = {
        { min = 80, max = 100, label = "Excellent", color = "#00ff00", effects = {} },
        { min = 60, max = 79, label = "Good", color = "#90ee90", effects = { stressShake = false } },
        { min = 40, max = 59, label = "Fair", color = "#ffff00", effects = { stressShake = true, panicChance = 5 } },
        { min = 20, max = 39, label = "Poor", color = "#ffa500", effects = { stressShake = true, panicChance = 15, visionBlur = true } },
        { min = 0, max = 19, label = "Critical", color = "#ff0000", effects = { stressShake = true, panicChance = 30, visionBlur = true, outburst = true } }
    },
    
    TherapyPrice = 150,
    TherapyDuration = 300, -- seconds
    
    Therapists = {
        Jobs = { "therapist", "doctor", "psychologist" },
        PaymentPerSession = 200
    }
}

-- Addiction System Configuration
ECHO.Addiction = {
    Enabled = true,
    
    Substances = {
        alcohol = {
            label = "Alcohol",
            addictionRate = 0.5, -- % per use
            withdrawalStart = 12, -- hours
            maxAddiction = 100
        },
        cannabis = {
            label = "Cannabis",
            addictionRate = 0.3,
            withdrawalStart = 24,
            maxAddiction = 100
        },
        cocaine = {
            label = "Cocaine",
            addictionRate = 2.0,
            withdrawalStart = 6,
            maxAddiction = 100
        },
        meth = {
            label = "Methamphetamine",
            addictionRate = 3.0,
            withdrawalStart = 4,
            maxAddiction = 100
        },
        prescription = {
            label = "Prescription Pills",
            addictionRate = 1.0,
            withdrawalStart = 8,
            maxAddiction = 100
        }
    },
    
    WithdrawalSymptoms = {
        { stage = 1, level = "Mild", effects = { "shaking", "sweating" }, statPenalty = 5 },
        { stage = 2, level = "Moderate", effects = { "shaking", "sweating", "nausea" }, statPenalty = 15 },
        { stage = 3, level = "Severe", effects = { "shaking", "sweating", "nausea", "hallucinations" }, statPenalty = 30 },
        { stage = 4, level = "Critical", effects = { "shaking", "sweating", "nausea", "hallucinations", "seizures" }, statPenalty = 50 }
    },
    
    RecoveryProgram = {
        MeetingInterval = 7200, -- seconds (2 hours)
        MeetingDuration = 600, -- 10 minutes
        RecoveryBonus = 5, -- % reduction per meeting
        SponsorBonus = 3, -- additional % with sponsor
        MinMeetings = 10, -- minimum to complete program
        
        Locations = {
            vector3(1853.42, 3685.96, 34.27),
            vector3(-264.47, -980.14, 31.22)
        }
    },
    
    Relapse = {
        ChanceReduction = 10, -- % per week clean
        BaseChance = 50 -- %
    }
}

-- General Settings
ECHO.Notifications = {
    Type = "default", -- default, qb, esx, ox, custom
    Position = "top-right"
}

ECHO.ProgressBar = {
    Type = "default", -- default, qb, esx, ox, custom
}

ECHO.Target = {
    Type = "qb-target", -- qb-target, ox_target, qtarget
    Enabled = true
}

-- Debug Mode
ECHO.Debug = false