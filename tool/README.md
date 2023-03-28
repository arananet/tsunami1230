# Tsunami tool
Tsunami card uses some advanced amiga features that are partially or not supported by some A1200 kickstarts:
- Kickstarts for A1200 <3.1 don't scan the local cpu fast ram area like A3000/4000 kickstarts do. Thus you need Kick 3.1 or later to use the fast-ram normally
- As today (kick 3.2.1), A1200 kickstarts don't scan ZorroIII autoconfig(TM) area, even when they have detected a 32 bit address capable cpu

# How to use
Put Tsunami tool at the start of your startup-sequence to gain additional features:
- Use the built-in fast-ram in unsupported kickstart versions
- Press Left-Alt when booting up to fully disable the accelerator card and get back to your A1200 original processor

# NOTES
- The disable feature works only on Rev1 or later tsunami boards


