# echo_health_system
Advanced Health &amp; Survival System - Organs, Mental Health, Addiction


Usage Commands


Player Commands:
/registerdonor - Register as organ donor (at hospital)
/browseorgans - View available organs (at hospital)
/requesttherapy - Request therapy from nearby therapist
/meditate - Self-meditation (60s cooldown)
/usesubstance [type] - Use substance (alcohol, cannabis, cocaine, meth, prescription)
/joinrecovery [substance] - Join recovery program
/attendmeeting [substance] - Attend AA/NA meeting (at meeting location)
/setsponsor [playerid] [substance] - Set recovery sponsor
/echohud - Toggle health HUD display
/echodebug - Toggle debug mode (admin only)

Admin/Medical Commands:
- Integration with your existing medical/admin systems
- Trigger events for organ harvesting during medical RP
- Mental health impacts from traumatic events
🔌 Integration Examples
Trigger Mental Health Impact


-- From other scripts
``
exports['echo_health_system']:AffectMentalHealth(source, 'witnessDeadBody')
Track Substance Use
``

-- When player uses drugs/alcohol
``
exports['echo_health_system']:TrackSubstanceUse(source, 'alcohol')
Check Organ Compatibility
``

-- Check if organ is compatible
local compatible = exports['echo_health_system']:CheckOrganCompatibility('O-', 'A+')
🎯 Features Summary
✅ Multi-Framework Support (QBCore, ESX, QBox, Custom)
✅ Organ Donation System (Legal & Black Market)
✅ Blood Type Compatibility
✅ Organ Decay & Quality System
✅ Mental Health Meter (5 stages with effects)
✅ Trauma Events (Panic attacks, outbursts)
✅ Therapy Sessions (Player-to-player RP)
✅ Addiction System (5 substances)
✅ Withdrawal Symptoms (4 severity stages)
✅ Recovery Program (AA/NA meetings)
✅ Sponsor System
✅ Complete UI (NUI with HUD)
✅ Database Logging
✅ Fully Optimized (0.00ms idle)

Made with ❤️ by ECHO