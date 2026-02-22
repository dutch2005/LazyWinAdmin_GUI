

# Update Work Experience, Certifications and Education from Resume

Update the `AboutSection.tsx` component to reflect your actual career history from your LinkedIn/resume PDF.

---

## Changes to `src/components/AboutSection.tsx`

### Work History (replace current 3 placeholder entries with your real timeline)

| Period | Role | Company/Client | Description |
|--------|------|-----------------|-------------|
| Apr 2022 -- Present | System Administrator | Mitsubishi Motors Europe B.V. (via Data4.nl) | System administration at Mitsubishi Motors, Maastricht-Airport |
| Jan 2021 -- Present | IT System Administrator | Data4.nl | Manage workplace and server environments (physical + virtual), remote support for customers |
| Oct 2021 -- Apr 2022 | Project Medewerker Extern | Zuyderland (via Data4.nl) | Project work at Zuyderland hospital, Sittard-Geleen |
| Oct 2019 -- Oct 2021 | System Administrator | Mitsubishi Motors Europe B.V. (via Data4.nl) | User accounts, Ivanti Workspace Control, Ivanti Automation, on-prem servers, MS Teams Calling, Azure projects |
| Sep 2018 -- Sep 2019 | Servicedesk Medewerker | Gemeente Maastricht (via Data4.nl) | IT support for municipality employees |
| Jul 2018 -- Jan 2019 | Intaker / Integrator | VodafoneZiggo (via Data4.nl) | Test installations, intake documents, application packaging |
| Sep 2018 -- Dec 2018 | ICT Medewerker | Catharina Ziekenhuis Eindhoven (via Data4.nl) | Printer/workstation replacement, HIX patient system rollout |
| Jan 2019 -- Feb 2019 | Servicedesk Medewerker | VieCuri Medisch Centrum (via Data4.nl) | Phone support for hospital staff |
| Dec 2016 -- Jun 2018 | Enterprise Servicedesk NS | KPN (via Data4.nl) | Enterprise service desk |
| Dec 2016 -- Jan 2021 | Medewerker Automatisering | Data4.nl | Automation work, Maastricht-Airport |
| Oct 2015 -- Dec 2016 | Customer Advisor Norton | Teleperformance Benelux | Technical support: installation, virus removal, product advisory |
| Jan 2015 -- Oct 2015 | Technisch Helpdeskmedewerker Ziggo | Teleperformance Benelux | Phone support for Ziggo TV, internet, VoIP customers |
| Jun 2009 -- Dec 2014 | Medewerker ICT | Stichting Jeugdzorg Sint Joseph | Helpdesk, printers, Dell switches, XenServer virtualization, user support |

To keep the section readable, the most recent/significant roles will be shown (roughly 6-7 entries), with older roles grouped or summarized.

### Certifications (replace current 2 with full list)

- 3CX Basic Certified Engineer V20
- 3CX Basic Certified Engineer v18
- Vibe Coding
- Ziggo Technische Training
- 70-697 Configuring Windows Devices

### Education (add new section)

- Arcus College -- Niveau 4, ICT Beheerder (2005--2009)
- Zuyd University of Applied Sciences -- HBO, Network Infrastructure Design (2004--2005)
- Sintermeerten College -- HAVO, Economie and Maatschappij (1997--2004)

### Languages (add new section)

- Dutch (Native)
- English (Full Professional)
- German (Limited Working)

### Skills update
- Add VoIP and 3CX to the skills grid (from Top Skills in resume)

---

## Technical Details

Only one file is modified: `src/components/AboutSection.tsx`

- The `workHistory` array will be replaced with your real positions (showing ~7 key roles, grouping short-term assignments)
- The `certifications` array will be expanded to 5 entries
- A new `education` array and `languages` array will be added with their own rendered sections
- The skills grid gains a VoIP/3CX entry
- All entries remain bilingual (NL/EN) following existing pattern
- The summary text ("10+ jaar" / "50+ projecten") stays accurate since your career spans 2009--present (15+ years)

