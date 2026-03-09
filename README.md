# My Custom Emacs Workflow
compact, pragmatic Emacs Org mode configuration focused on time tracking, quick org-capture templates (including a sleep-duration capture), automatic daily archival of time.org into a year/month memory tree, and monthly training-file generation. This README explains what the setup does, how to install it, and how to customize it.

Applies a minimalist UI (hides menu, toolbars, scrollbars) and uses modus-vivendi theme.

Adds org capture templates for quick notes, time items, and a "Sleep" template that computes duration and writes a CLOCK line.

On Emacs start, archives time.org into ~/Nextcloud/memory/YYYY/MM/time-YYYY-MM-DD.org if it was last modified on a previous day and recreates a fresh time.org
Auto-creates a training-YYYY-MM.org file for the current month (one heading per day) under ~/Nextcloud/memory/YYYY/MM/

File structure: main files are time.org for daily time tracking and metrics of performance,
tasks.org to plan by time and by category, subheadings include tommorow, to search, to buy....
random.org to capture text to be moved later

Notes can be captured and connected for later analysis

## Installation
1. Clone this repo.
2. Run the symlink command.


Future directions:
merge into the digital brain setup so that the code that implements the knowledge base there talks with the org mode setup
