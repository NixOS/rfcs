---
feature: nixpkgs-review-mcp
start-date: 2026-04-01
author: Morgan Jones
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Many projects, especially ones that converge around complex tools, are standardizing around creating MCPs for giving external agents access to useful utilities. In this RFC, I propose a new MCP for nixpkgs-review with a live implementation that contributors can use right now to speed along their PR reviews.

# Motivation
[motivation]: #motivation

## Long PR delays

It is well known that getting anything reviewed in nixpkgs takes a long time. Assuming an average of 30 minutes of review time, the 10,800 open PRs would take 0.6 years to review. As the amount of software in the world is expected to grow exponentially in the next few years, additional methods for contributors to review things will reduce friction and result in faster updates and additions of packages.

## Contributor agency

Contributors are using new tools to review their PRs, and the concept of MCPs is not new as a form of [in-band signaling](https://en.wikipedia.org/wiki/In-band_signaling).

For instance, engineers used [Q codes](https://en.wikipedia.org/wiki/Q_code#Later_use) in the days of telegraphy as tools to ask their conversation partner their distance and bearing. When telephony became automated, we got the famous [2600 hertz](https://en.wikipedia.org/wiki/2600_hertz) tones to control telephone backplanes. Sometimes in-band signaling is just convenient, more recently with systems like [chatops](https://aws.amazon.com/chatbot/) to manage EC2 resources from Slack.

We should let people contribute how they feel comfortable ⸻ hence the need for a nixpkgs-review MCP.

# Detailed design
[design]: #detailed-design

Note: The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

This document specifies the **nixpkgs-review Morse Code Protocol** (MCP), which can be used to do reviews at up to 75 tokens per minute, depending on skill.

## Reviewer requirements

To correctly implement the nixpkgs-review MCP, reviewers MUST advertise a frequency on an amateur radio band that allows transmitting CW (continuous wave) signals including Morse code. Receivers SHOULD additionally advertise a grid square in [Maidenhead](https://en.wikipedia.org/wiki/Maidenhead_Locator_System) format, so contributors can know which heading to point their antenna. Reviewers MAY advertise a callsign, though callsigns are not required to receive MCP commands.

### Band plan

For ease of use, we define frequencies in many bands that can be used for the MCP:

|Band|Frequency|
|:---|:--------|
|160 meters|1.899 MHz|
|80 meters|3.599 MHz|
|60 meters|5.349 MHz|
|40 meters|7.099 MHz|
|30 meters|10.109 MHz|
|20 meters|14.099 MHz|
|17 meters|18.099 MHz|
|15 meters|21.099 MHz|
|12 meters|24.899 MHz|
|10 meters|28.099 MHz|
|6 meters|50.099 MHz|
|2 meters|144.099 MHz|
|1.25 meters|222.99 MHz|
|70 cm|420.69 MHz|

This has the benefit of giving us more 9s than GitHub, since 9s are in high demand these days.

### Software

It is RECOMMENDED for reviewers to have software running that allows for the automatic decoding of CW, [like this one](https://github.com/numinit/ifttx) based on [fldigi](https://search.nixos.org/packages?channel=unstable&query=fldigi). Alternatively, reviewers MAY do so by hand, provided that they are willing to enter nixpkgs-review commands manually and do not have a skill issue.

Correct review messages follow this ABNF:

```
MCP = [RECEIVER PAUSE] [SENDER PAUSE] "PR" PAUSE (NUMBER / RESULT)
RECEIVER = "CQ" / CALLSIGN
SENDER = CALLSIGN
CALLSIGN = 3*6(ALPHA / DIGIT)
PAUSE = [SP]
NUMBER = 6*7DIGIT
RESULT = ("LGTM" / "NAK") PAUSE NUMBER
```

Note that we define the PAUSE symbol as an optional space. There is frequent disagreement on what counts as a "space" in Morse code, so this definition SHOULD make everyone happy. (If it doesn't, you know exactly where to complain).

Callsigns are OPTIONAL in the protocol to facilitate correct decoding of more MCP commands, though they SHOULD be sent. If they are successfully decoded, they SHOULD be compared against the receiver's callsign, if any. Note that CQ is a valid callsign referring to anyone, because there are [always other receivers.](https://local58.tv/)

### Correct nixpkgs-review invocation

Reviewers SHOULD use an invocation similar to `nixpkgs review pr $NUMBER --post-result` given a MCP message `PR $NUMBER`.

Reviewers MAY include, in the result template, details about the frequency and grid square that the review was performed from, as well as information about their antenna.

Reviewers MAY also attach a [QSL card](https://en.wikipedia.org/wiki/QSL_card) to the review comment confirming contact.

If the PR is reviewed successfully, the reviewer MAY send back a result message, e.g. `PR LGTM $NUMBER` or `PR NAK $NUMBER`. However, the GitHub issue is the place that takes priority.

## Contributor requirements

To use the nixpkgs-review MCP, a contributor MUST have a radio transmitter and antenna tuned to the correct frequency, and SHOULD have an amateur radio license.

The contributor simply performs the opposite of the reviewer; that is, encodes the MCP message as CW and sends it to a reviewer. 

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

- `CQ K1ABC PR 123456`: K1ABC wants anyone to review #123456
- `K1ABC W2DEF PR NAK 123456`: W2DEF says you need to fix #123456
- `W2DEF K1ABC WTF SRSLY`: K1ABC is annoyed that their PR got a NAK

## Live instance

21.099 MHz, grid DM13. Receive only mode for now, will reply using nixpkgs-review on the GH issue.

Yes, this is real. If you get CW down to southern California and fldigi decodes it, you'll get your PR merged if it passes review (and other checks). Try it.

(If you want a review on another frequency, let me know, I'll likely be switching to 30 and 40 at night in the US).

# Drawbacks
[drawbacks]: #drawbacks

Everyone needs a radio and a large antenna. While this may use a similar amount of power to a GPU, it runs in multiplayer mode by default.

# Alternatives
[alternatives]: #alternatives

Model Context Protocol, which was briefly considered before more token-efficient alternatives were chosen.

# Prior art
[prior-art]: #prior-art

- https://github.com/NixOS/nixpkgs/pull/441048#issuecomment-3265365059
- https://github.com/NixOS/nixpkgs/pull/427048#issuecomment-3265399043
- https://github.com/NixOS/nixpkgs/pull/486609
- https://github.com/Mic92/nixpkgs-review
- https://sourceforge.net/projects/fldigi/
- RFC 173, [NixOS Hotline](https://github.com/NixOS/rfcs/pull/173)

# Unresolved questions
[unresolved]: #unresolved-questions

- Can we use RTTY for review comments?
- What about WEFAX for faxing each other diffs?
- Does Morse Code actually have spaces?
- Will amateur radio tools ever have good UX?
- How do we improve the experience for people who live in grid square RR73?
