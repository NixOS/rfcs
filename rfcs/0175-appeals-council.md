---
feature: Memorandum of Understanding on Equitable Moderation
start-date: 2024-04-24
author: nrdxp
co-authors: apcodes
shepherd-team:
shepherd-leader:
related-issues:
---

# Summary
[summary]: #summary

- The primary objective of this RFC is to fundamentally enhance the existing moderation practices to ensure fairness and transparency within our community.

- We propose the adoption of a *Memorandum of Understanding on Equitable Moderation* (hereinafter referred to as the *Memorandum*), establishing a foundation for reasonable expectations within a community of equal and reasonable contributors.

- To prevent the abuse of exclusionary power inherent in community moderation, we aim to establish an *Appeals Council* with a diverse composition.

- This council will ensure adherence to the standards set forth in the *Memorandum*.

# Motivation
[motivation]: #motivation

The existing moderation structure has evolved from a series of compromises designed to balance the need for formal community governance with a preference for a less extensive approach than that of the unsuccessful RFC 98.

Governance must be legitimate, grounded in a clear understanding of its purpose, powers, and limitations. Recent controversial moderation decisions, particularly the bans of prominent community members Srid and blaggacao, have, in our view, lacked sufficient explanation, violating the principle of transparency to which the current moderation team is committed.

The absence of clear, accessible reasons for these decisions suggests that the current community moderation structure requires significant improvement.

Despite these issues, we firmly believe in the necessity of a fair and equitable moderation structure for the community's functionality. We are confident that improvements can be made within the existing institutional framework, but substantive changes are necessary to achieve a more desirable state of affairs.

In accordance with RFC 102, the moderation team uses the NixOS foundation mission statement as a guideline. However, the interpretation of this mission statement and the subsequent [Code of Conduct][coc] is largely at the team's discretion. RFC 102 acknowledged the absence of explicit guidance on this matter.

We contend that this ambiguity has allowed the moderation team to shape community values without consent, either direct or implied. The exercise of power in this manner, to suppress reasonable dissent and foster an illusion of unity, has a chilling effect that hinders productive dialogue and ultimately harms the project.

This proposal seeks to establish clear foundations for a shared understanding of moderation practices through the *Memorandum of Understanding on Equitable Moderation* and to ensure these foundations are upheld in practice. It aims to prevent the NixOS foundation mission statement from being misused to enforce a homogenizing moderation policy.

The *Memorandum* should be seen as a normatively binding interpretation of the moderation team's mission statement.

This document aims to articulate an overlapping consensus on reasonable expectations for anyone participating as an equal member in this community, emphasizing that community members are accountable to moderation and vice versa.

# Detailed Design
[design]: #detailed-design

## Goals

- Adopt the *Memorandum of Understanding on Equitable Moderation* to foster a shared understanding of equitable moderation practices that accommodate a community with diverse sociopolitical views.
- Ensure transparent accountability of moderation practices to community members.
- Ground community member accountability in publicly available general principles, providing a stable basis for behavioral expectations.
- Make wide-ranging decisions regarding community member exclusion understandable.
- Promote a diverse moderation team to balance diverse perspectives on controversial issues.
- Establish an *Appeals Council* to hold moderation team members and procedures accountable and to allow for the revision of significant decisions if they fail to meet the community's reasonable standards.

## Memorandum of Understanding on Equitable Moderation

In response to the impression left by past events and with a fervent desire for improvement, we adopt the following principles and maxims as the *Memorandum of Understanding on Equitable Moderation*. These principles serve to clarify the overlapping consensus on reasonable expectations for community participation:

1) We, as moderators, commit to basing decisions on general principles and concrete reasons that apply equally to all community members, irrespective of characteristics such as sociopolitical orientation, economic status, identity, or religion.
2) We adhere to the principles of *equality* and *objectivity*. Equality refers to the status of each community member, while objectivity pertains to the consistent, unbiased reasoning behind our decisions.
3) A *concrete reason* is a verifiable state of affairs that can be demonstrated to other community members upon request.
4) We acknowledge that *concrete reasons* are not self-explanatory, except in extreme cases, and we will provide explanations relating them to the general principles guiding our decisions.
5) We affirm that moderation actions must be fair and proportionate to the related issue.
6) We ensure that concrete reasons for permanent bans are available for inspection by long-standing community members.
7) We recognize that moderation actions should not be based solely on the volume of complaints.
8) We commit to treating community members with respect and avoiding derogatory language when addressing concerns.
9) We affirm our role as moderators is to facilitate a respectful community, not to punish members. We will use language that reflects mutual respect.
10) We prefer inclusion to exclusion, resorting to permanent exclusion only in cases of extreme necessity. We are committed to exploring ways to prevent exclusion and to engaging constructively in efforts to reinstate excluded members.
11) To reflect a consensus in a diverse community, the moderation team must embody cultural and viewpoint diversity, respecting members with varying societal views, provided they do not undermine equal community membership.
12) We respect viewpoint diversity in cultural and political matters when selecting moderation team candidates.
13) We understand that reasonable moderation is based on past events or future expectations, necessitating respect for historical records and transparency in controversial events.
14) We uphold that true diversity necessitates exceptional tolerance, actively embracing not only the ideas we favor but, also, those we disagree with. This commitment to tolerance is fundamental in fostering a community where diverse viewpoints can coexist and enrich our collective experience.

## Resolution to Adopt the *Memorandum*

- Incorporate the *Memorandum* text into the moderation repository on GitHub, linking it prominently from the Code of Conduct and all relevant public information sources.
- Implement one-year term limits for moderation team members, with a one-year hiatus before potential return. Apply this rule retroactively.
- Align the current moderation team composition and the Code of Conduct with the *Memorandum* principles within three months of adopting this document.

## Resolution to Establish an Appeals Council

- Form an *Appeals Council* of three long-standing community members, reflecting cultural and viewpoint diversity.
- Exclude current moderation team members from the *Appeals Council*, with former members eligible after a one-year hiatus.
- Grant the council authority to override moderation team nominations, overturn decisions, and end moderation team memberships that conflict with the *Memorandum* principles.
- Adopt a 2/3 majority rule for council decisions, disallowing abstentions to avoid indecision.
- Allow community members equal rights to appeal to the *Appeals Council* regarding its powers, with limitations on appealing disciplinary bans to cases exceeding three months.
- Ensure timely appeal decisions within two months and make the council's reasoning publicly accessible upon request.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

In response to recent contentious events and the existing moderation team's failure to adequately address perceived inconsistencies in moderation practices, we have compiled a detailed document of evidence. This document is essential to demonstrate the urgent need for the *Memorandum of Understanding on Equitable Moderation*. The evidence collected underscores the patterns of abuse of power and a prevailing culture of silence that have necessitated this proposal. Due to the sensitive and potentially inflammatory nature of the contents, we have chosen to host this evidence externally to ensure that discussions around it are approached with the necessary caution and context:

- [Appendix of Evidences & Experiences][evidences]

In addition, since we have been banned from participating in the discussion immediately after posting the RFC, we decided to start responding to some of the more egregious posts in a separate document in order to defend our postion.

- [Appendix of Comment Responses][responses]

# Drawbacks
[drawbacks]: #drawbacks

While the proposed *Memorandum of Understanding on Equitable Moderation* and the establishment of an *Appeals Council* aim to enhance fairness and transparency in moderation practices, there are several potential drawbacks to consider:

1. **Complexity and Bureaucracy**: The introduction of the *Memorandum* and the *Appeals Council* could potentially increase the complexity of the moderation process. This might lead to slower decision-making and could require more resources to manage effectively. The need for detailed explanations and adherence to the *Memorandum* might also add bureaucratic layers that could hinder swift action when needed.

2. **Potential for Conflict**: The establishment of an *Appeals Council* with the power to override decisions made by the moderation team could lead to conflicts between these two bodies. This might result in inconsistencies in moderation actions and could potentially create divisions within the community if not managed carefully.

3. **Resource Intensiveness**: Implementing and maintaining the structures proposed in the RFC, such as the *Appeals Council* and the ongoing review of moderation actions as per the *Memorandum*, will require significant time and effort from community members. This could divert attention and resources away from other important projects and initiatives within the community.

4. **Risk of Over-Regulation**: While the *Memorandum* aims to provide clear and equitable guidelines for moderation, there is a risk that these rules could become overly restrictive. This might stifle the organic growth and evolution of community norms and could discourage community members from participating in moderation due to fear of making mistakes or being perceived as biased.

5. **Challenge in Achieving Diversity**: The goal of ensuring that the moderation team and the *Appeals Council* reflect cultural and viewpoint diversity is commendable. However, achieving this diversity in practice can be challenging. There is a risk that the selection process could become contentious or that it might not be possible to find suitable candidates who meet all the desired criteria.

6. **Unintended Consequences**: Any change in governance structures can have unintended consequences. For example, the introduction of term limits for moderation team members might lead to a loss of experienced moderators, which could impact the quality of moderation in the short term. Additionally, the requirement for transparency and detailed explanations could inadvertently lead to privacy concerns or the sharing of sensitive information.

Despite these potential drawbacks, the need for reform is driven by the already severely eroded trust in the existing moderation team. The community's confidence has been significantly undermined by a series of controversial decisions and a perceived lack of transparency and fairness. This situation has created a pressing need for changes that can restore trust and ensure a moderation process that is perceived as just and equitable by all community members.

By acknowledging these potential drawbacks, the community can better prepare for and mitigate these challenges as it works to implement the proposed changes. The benefits of restoring trust and improving the moderation framework are considered to outweigh the risks and costs associated with the proposed reforms. The commitment to transparency, fairness, and inclusivity is expected to foster a stronger, more cohesive community, ultimately benefiting the project as a whole.

# Alternatives
[alternatives]: #alternatives

This section explores possible alternatives to the proposed *Memorandum of Understanding on Equitable Moderation* and the establishment of an *Appeals Council*. Each alternative is assessed for its potential impact on the community and its alignment with the community's values and needs.

## Continue with the Status Quo

- **Description**: This alternative involves maintaining the current moderation practices without any significant changes.
- **Implications**: While this approach requires the least effort in terms of implementation, it risks further erosion of trust within the community. The recent controversies and perceived inconsistencies in moderation could continue to alienate members and may lead to a decline in active participation and contributions.
- **Evaluation**: Given the current dissatisfaction expressed by parts of the community, continuing with the status quo is likely to be unsustainable and could exacerbate existing tensions.

## Decentralize Moderation Responsibilities

- **Description**: Instead of a centralized moderation team, moderation responsibilities could be distributed among a larger group of trusted community members.
- **Implications**: This could potentially increase the transparency and fairness of moderation decisions, as more viewpoints would be involved in the decision-making process. However, it might also lead to further inconsistencies in how rules are applied and complicate the coordination of moderation actions.
- **Evaluation**: While decentralization could address some concerns about power concentration and lack of representation, it requires robust mechanisms for coordination and conflict resolution to be effective.

## Implement Automated Moderation Tools

- **Description**: Utilize software tools to automate certain aspects of moderation, such as detecting and handling clear-cut cases of rule violations.
- **Implications**: Automation could increase the efficiency of moderation and reduce the burden on human moderators. However, over-reliance on automation could lead to errors, such as inappropriate bans or failure to capture the nuances of human interactions.
- **Evaluation**: While helpful as a supplementary tool, automation cannot fully replace human judgment, especially in complex or sensitive cases. It should be used cautiously to support, not replace, human moderators.

## Conclusion

After considering the alternatives, it becomes evident that while each option has its merits, none fully address the comprehensive needs of the community as effectively as the proposed *Memorandum of Understanding on Equitable Moderation* and the establishment of an *Appeals Council*. These proposals aim to create a more transparent, fair, and accountable moderation system that aligns with the community's values of diversity and open dialogue.

# Prior art
[prior-art]: #prior-art

[RFC 98](https://github.com/NixOS/rfcs/pull/98)
[RFC 102](https://github.com/NixOS/rfcs/pull/102)
[RFC 114](https://github.com/NixOS/rfcs/pull/114)



# Unresolved Questions
[unresolved]: #unresolved-questions

- It may be the case that not all participants in the current community around NixOS/Nix are reasonable actors desiring a community of diverse yet equal participants, but rather prefer to exclude people on unreasonable grounds to satisfy a purely subjective desire or feeling.
- How will the *Memorandum* and the *Appeals Council* adapt to the evolving needs and values of the community over time, ensuring that they remain relevant and effective?
- What mechanisms will be put in place to evaluate the effectiveness of the *Memorandum* and the *Appeals Council* in achieving their intended goals, and how frequently will this evaluation occur?
- What steps will be taken to maintain the confidentiality and privacy of individuals involved in moderation disputes, especially in cases where sensitive issues are being discussed?
- What strategies will be implemented to ensure that the cultural and viewpoint diversity of the moderation team and the *Appeals Council* is truly representative of the community's demographics?

These unresolved questions highlight areas where further discussion and planning may be necessary to ensure the successful implementation and operation of the proposed *Memorandum* and *Appeals Council*. Addressing these questions will help to anticipate challenges and prepare more comprehensive solutions.

[evidences]: https://github.com/nrdxp/rfc-evidence/blob/master/rfc_evidences_experiences.md
[responses]: https://github.com/nrdxp/rfc-evidence/blob/master/thread_responses.md
[coc]: https://github.com/NixOS/.github/blob/master/CODE_OF_CONDUCT.md
