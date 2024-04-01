# RFC nixos hotline

---
feature: NixOS PR hotline
start-date: 2024-04-01
author: trollulus
co-authors: riotbib, rtrollreal, b-kenji, zmberber, kmein
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Bring the Power of German bureaucracy to Nixpkgs by using a sophisticated telephone system to interact with pull requests.

# Motivation
[motivation]: #motivation

As recent surveys <sup>[citation needed]</sup> have shown a near 80% dominance of the German language in nixpkgs, we want to align the nixpkgs workflow with the natural way German people interact with complex systems.
Also, there are a lot of open pull requests and the amount of work doesn't seem to scale for our small group of contributors. By establishing a way to interact with nixpkgs without the need for a computer or a smartphone, we unlock a lot of potential contributors.

# Detailed design
[design]: #detailed-design

We establish a hotline ``+49 0800 64967(NIXOS)`` where users can interact with nixpkgs. The system will be in German since that is the most spoken language in the nixpkgs community.

Users will be able to get a list of open pull requests by navigating an interactive menu (see examples). And also be able to merge or write reviews/comments.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## example interaction (translation is further down)
- User dials `+49 0800 64967(NIXOS)`
- AI voice greets caller in German:
```
Willkommen beim Deppendrehkreuzziehbegehrassistenten für Nixpkte.
Bitte drücken Sie die 1, wenn Sie Liste an offenen Ziehbegehren erhalten wollen.
Drücken Sie 2, falls Sie direkt zu einem bestimmten Ziehbegehren gehen wollen.
Drücken Sie 3, falls Sie nach einem bestimmten Benutzer filtern möchten.
```

- User presses 3

```
Bitte nennen Sie den Namen des Nutzers nachdem Sie filtern wollen.
```

- User says Mic92
```
Ich habe MichaelZweihundert verstanden, ist dies korrekt?
```

- User says no

```
Können Sie den Namen wiederholen?
```

- User says Mic92

```
Ich habe MicDreiundneunzig verstanden, ist dies korrekt?
```

- User says no
```
Können Sie den Namen wiederholen?
```

- User says Mic92

```
Ich habe MicNeunDrei verstanden, ist dies korrekt?
```

- User says no

```
Leider sind unsere Sprach-zu-Text-Rohrleitungen gerade alle belegt. Stattdessen werden wir Ihnen nun alle offenen Ziehbegehren des Nutzers r-ryantm vorlesen.

- Ziehbegehren 299112: Python Drei Elf Pakete Punkt AIO ESP Heim API. Dreiundzwanzig Punkt Eins Punkt Null Pfeil Dreiundzwanzig Punkt Zwo Punkt Null
- Ziehbegehren 299106: D DNS Minus gehen. Sechs Punkt Zwo Punkt Zwo Pfeil Sechs Punkt Drei Punkt Null
(etc.)

- Bitte drücken Sie die Nummer der Ziehbegehren, die Sie bearbeiten wollen.
```

- User presses 299106

```
Willkommen bei dem Ziehbegehren 299106.
Bitte drücken Sie die 1, um alle Kommentare vorzulesen.
Drücken Sie die 2, um dieses Ziehbegehren zu schliessen.
Drücken Sie die 3, um dieses Ziehbegehren zu verschmelzen.
Drücken Sie die 4, um eine Rezension zu hinterlassen.
```

- User presses 3

```
Bitte geben Sie Ihren Privatschlüssel jetzt im Nummernfeld an. Achten Sie bitte darauf, dass Sie Ihren Schlüssel erst in Basis 10 konvertiert haben müssen.
```

- User presses 111 112 101 110 115 115 104 45 107 101 121 45 118 49 0 0 0 0 4 110 111 110 101 0 0 0 4 110 111 110 101 0 0 0 0 0 0 0 1 0 0 0 51 0 0 0 11 115 115 104 45 101 100 50 53 53 49 57 0 0 0 32 81 15 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 1014 80 41974 80 40960 0 11 115 115 104 45 101 100 50 53 53 49 57 0 0 0 32 81 15 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 64 2399 1243 115 101 112 89 27 34727 33 107 6827 64594 80 86 80 125 43 10 36 49 9295 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 12 108 97 115 115 64 105 103 110 97 118 105 97 2

```
Leider ist der von Ihnen eingegebene Schlüssel nicht korrekt, versuchen Sie es bitte erneut.
```

- User presses 111 112 101 110 115 115 104 45 107 101 121 45 118 49 0 0 0 0 4 110 111 110 101 0 0 0 4 110 111 110 101 0 0 0 0 0 0 0 1 0 0 0 51 0 0 0 11 115 115 104 45 101 100 50 53 53 49 57 0 0 0 32 81 15 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 1014 80 41974 80 40960 0 11 115 115 104 45 101 100 50 53 53 49 57 0 0 0 32 81 15 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 64 2399 1243 115 101 112 89 27 34727 33 107 6827 64594 80 86 80 125 43 10 36 49 9295 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 12 108 97 115 115 64 105 103 110 97 118 105 97 1

```
Vielen Dank, das Ziehbegehren 299106 wurde nun in den Hauptzweig verschmolzen. Auf Wiederhören.
```

## translation of example interaction

- User dials `+49 0800 64967(NIXOS)`
- AI voice greets caller in German:

```
Welcome to the Github pull request assistant for Nixpkgs.
Please press 1 to get the list of open pull requests.
Press 2 if you want to go to a specific pull request.
Press 3 if you want to filter after a specific user.
```
- User presses 3

```
Please tell us the name of the user you want to filter.
```
- User says Mic92

```
I understood MichaelTwohundred, is this correct?
```

- User says no


```
Could you please repeat the name?
```

- User says Mic92

```
I understood MicNinetyThree, is this correct?
```

- User says no
```
Could you please repeat the name?
```

- User says Mic92

```
I understood MicNineThree, is this correct?
```

- User says no

```
Sadly all our speech to text pipelines are busy. Instead we will read to you all pull requests by r-ryantm.

- pull request number 299112: Python 3 point eleven AIO ESP Home API. twentythree point one point zero arrow twentythree point two point zero
- pull request number 299106: D DNS dash go. six point two point two arrow six point three point zero
(etc.)

- please press the number of the pull request you want to edit.
```

- User presses 299106

```
welcome to the pull request 299106
please press 1 to listen to all comments.
press 2 to close this pull request.
press 3 to merge this pull request.
press 4 to leave a review.
```

- User presses 3

```
Please enter your private key on the dialpad. Take care, that the private key has to be converted to base 10 first.
```

- User presses 111 112 101 110 115 115 104 45 107 101 121 45 118 49 0 0 0 0 4 110 111 110 101 0 0 0 4 110 111 110 101 0 0 0 0 0 0 0 1 0 0 0 51 0 0 0 11 115 115 104 45 101 100 50 53 53 49 57 0 0 0 32 81 15 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 1014 80 41974 80 40960 0 11 115 115 104 45 101 100 50 53 53 49 57 0 0 0 32 81 15 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 64 2399 1243 115 101 112 89 27 34727 33 107 6827 64594 80 86 80 125 43 10 36 49 9295 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 12 108 97 115 115 64 105 103 110 97 118 105 97 2

```
sadly the private key you entered is incorrect, please try again.
```

- User presses 111 112 101 110 115 115 104 45 107 101 121 45 118 49 0 0 0 0 4 110 111 110 101 0 0 0 4 110 111 110 101 0 0 0 0 0 0 0 1 0 0 0 51 0 0 0 11 115 115 104 45 101 100 50 53 53 49 57 0 0 0 32 81 15 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 1014 80 41974 80 40960 0 11 115 115 104 45 101 100 50 53 53 49 57 0 0 0 32 81 15 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 64 2399 1243 115 101 112 89 27 34727 33 107 6827 64594 80 86 80 125 43 10 36 49 9295 176 105 61 9 26 72 71 82 53 65 127 33532 105 49882 26415 38 114 96 1859 38 7 896 0 0 12 108 97 115 115 64 105 103 110 97 118 105 97 1

```
Thank you, the pull request 299106 was merged into the master branch. see you later aligator.
```


# Drawbacks
[drawbacks]: #drawbacks

None are obvious, this seems like a perfect system.

# Alternatives
[alternatives]: #alternatives

Fax, Letters, pidgeons. These are not really alternatives though as they are more of addons.

Human operator fallback.

The ability to go to a physical office, but only on the fourth Friday in uneven months between 7:30 and 8:15 am with an appointment via hotline.

# Prior art
[prior-art]: #prior-art

This is the first time someone had this great idea.

- https://github.com/danielauener/git-auf-deutsch

# Unresolved questions
[unresolved]: #unresolved-questions

Do we still need the classical web system if we have this superior system?

# Future work
[future]: #future-work

This is the work of the future.
