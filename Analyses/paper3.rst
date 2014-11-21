1
Variable Length On-Line Document Generation
331
Title
2
Michael O'Donnell
331
Author
3
University of Edinburgh
331
Institution
4
This paper describes a system for {\em variable-length document presentation}
332
span
5
on-line documents whose length can be adjusted to the user's demands.
4
Re-state
6
The system depends on an initial marking-up
333
span
7
of documents
6
Affected
8
using an {\em RST Markup Tool}
334
span
9
- a graphical interface
335
span
10
for marking up the rhetorical structure
336
span
11
of a text.
10
Owner
12
During presentation,
13
Temporal-Location
13
the rhetorical structure is used
337
span
14
to prune the text
13
Purpose
15
down to the size requested
338
span
16
by the user,
15
Agent
17
allowing retention of the essentials
339
span
18
of the text.
17
Owner
19
\section{Introduction}
340
Heading
20
As we move into the the use of the web,
21
Temporal-Extent
21
more and more documents are becoming available on-line.
341
span
22
However, different users have different needs
343
span
23
from these documents.
22
Spatial-Location
24
Some users, in a hurry, may desire brief and succinct documents.
344
Contrast
25
Others may require more detail.
344
Contrast
26
Users may also vary as to the type of information they want
345
span
27
from a document.
26
Spatial-Location
28
This paper describes an experiment with on-line text presentation
346
span
29
-- whereby the user specifies how long the document should be.
347
Sequence
30
The system then presents a coherent document
348
span
31
fitting that space limitation.
30
Matter
32
The user might choose to see the hundred-word version, or the thousand-word version, or somewhere between.
28
Detail
33
Figure~\ref{fig:fullpage} shows the web browser (Netscape) interface
349
span
34
to the system,
33
medium
35
also showing (part of) the text
350
span
36
before it is reduced.
35
essential
37
Figure ~\ref{fig:brief} shows the same document, although with a 200 word limit set.
351
span
38
The text is mostly coherent,
353
span
39
with however some minor problems.
354
span
40
One can see these as the cost of this sort of summarisation.
39
Comment
41
Figure: fullpage1.eps
355
Graphic
42
Caption: The VLTP interface
355
Caption
43
Figure: 200.eps
356
Figure
44
Caption: Scottish History text at 200 words
356
Caption
45
This technique, what we call {\em  variable-length text presentation}, involves
375
span
46
two steps:
45
medium
47
{\bf Document Preparation}:
357
span
48
the document is marked-up
358
span
49
according to its rhetorical structure.
48
medium
50
For this
51
high
51
we use an RST Analysis Tool,
359
span
52
which allows a user to graphically link segments
360
span
53
of text
52
medium
54
into an RST-tree.
52
Result
55
{\bf Document Presentation}:
361
span
56
a web-connected program is then used to present such documents.
362
span
57
In response to a user's request,
58
Cause
58
the program `prunes' off less essential branches
363
span
59
of the RST-tree
58
Owner
60
until a text of the required size is produced.
58
Temporal-Extent
61
The system was an attempt to see how far we could push a notion
364
span
62
mentioned by Sparck Jones (1993),
61
Background
63
that RST can be used to summarise a text,
365
span
64
shaving off less relevant satellites.
63
Elaboration
65
Can we remove rhetorically dependent sub-sections
376
span
66
of the text
65
Owner
67
without markedly affecting the coherence
366
span
68
of the text?
67
Affected
69
Our pruning method involves assigning a level of relevance between 0 and 1 to each RST relation.
367
Sequence
70
Using these values,
71
Method
71
we can work out the relevance of each node
368
span
72
in the RST-tree:
71
Spatial-Location
73
the top-node having 1.0 relevance,
369
Sequence
74
each of  satellite in the tree having relevance proportional to the relevance of its nucleus times the relevance of the relation linking it.
369
Sequence
75
We then prune off text-nodes with lowest relevance
370
span
76
until the required word-limit is reached.
75
Temporal-Extent
77
This process is described in section 3.
370
Comment
78
The system also allows a small degree of user-determination
377
span
79
of the content.
78
Affected
80
The RST-pruning uses information on the relative importance of each RST relation.
378
Background
81
If the user is given control of these importances,
82
Condition
82
then they can tailor the kinds of information that is actually left
378
span
83
in the document.
82
Spatial-Location
84
In section 4,
85
Spatial-Location
85
we address various areas of incoherence
381
span
86
introduced by the pruning
85
Elaboration
87
(paragraphing, punctuation, reference and discourse markers),
85
Instantiate
88
and our solutions
383
span
89
to these problems.
88
Matter
90
In section 5,
91
Spatial-Location
91
we describe the RST markup tool
384
span
92
which makes it possible
372
span
93
to conceive of document presentation
373
span
94
based on RST markup.
93
essential
95
RST-based document summarisation has been stopped
374
span
96
in the past
95
Temporal-Location
97
because of the  poor state of automatic discourse structure recognition.
374
Reason
98
Hand-markup is an arduous task,
387
span
99
but the tool we report here makes the task economical
386
span
100
for some documents.
99
medium
101
However, keep in mind that
103
low
102
because of the time-cost of document markup,
103
Reason
103
this technique is only useful for documents with a longer shelf-life.
388
span
104
We must weigh the cost of analysing the original document against the benefits of having a variable-length on-line document.
103
Elaboration
105
Finally, section 6 will attempt to assess the usefulness
390
span
106
of this approach,
105
high
107
detailing the quality of the presented documents,
105
Elaboration
108
against the problems involved
389
span
109
in the presentation.
108
Spatial-Location
110
Some extensions of the work are also suggested.
105
Elaboration
111
\subsection{Relevance to Generation}
392
Heading
112
Given that this technique  involves neither text-planning nor sentence-planning,
113
Background
113
one might ask how this paper is relevant


114
to the Generation community.
113
medium
115
Firstly, the technique of {\em RST-pruning}, reported in section 2, is applicable to pruning


116
of RST-structures
393
span
117
generated by a full-blown text-planner.
116
Elaboration
118
A text-planner could produce fully-elaborated rst-structures


119
from an underlying knowledge-base,
118
medium
120
and then present pruned versions of the text


121
depending on the users needs.
120
low
122
We can thus apply the techniques reported here


123
for variable-length document presentation
122
Matter
124
to variable-length document {\em generation}.
122
high
125
Secondly, this work is also of interest to the Generation community


126
because of the contained report of the RST Markup Tool.
402
span
127
RST is used widely within the generation community,
400
Background
128
and this tool may prove useful to many,
400
span
129
not only as an aide in their corpus studies,
399
Contrast
130
but also for preparing diagrams for publications.
399
Contrast
131
\subsection{Related Work}
394
Heading
132
Summarisation via RST-pruning was suggested by  Sparck Jones (1993),
397
span
133
although the mechanism for determining which satellites to prune is unique here.
132
Concession
134
Also, her work was limited by the lack of automated RST analysis,
395
span
135
while I rely on semi-automated markup.
134
Comparison
136
The application of the technique to produce variable-length documents is also unique.
132
Concession
137
Rino \& Scott (1996) offer a more detailed account of summarisation via pruning
394
Point
138
n a full generation environment.


139
However, they prune the content structure rather than the discourse structure.


140
The RST tree produced to express the pruned content structure is not itself pruned.


141
On the other hand,


142
their content structure is similar enough to RST that similarities to the present work are observed.


143
They take intention structure into account to drive the pruning,


144
which would be a valuable addition to the methods proposed here.


145
While I believe they are right in that text summarisation needs to take both these areas (and others) into account, I am interested here to see how well rhetorical structure by itself can form the basis of summarisation.


146
Ed Hovy, in his involvement with the HealthDoc project, has suggested generation from a master document -- a set of SPL (semantic specifications of sentences), each conditionalised by the user model (see DiMarco et al 1995).


147
The text actually seen by the user is achieved by pruning out SPLs which are inappropriate for the user-type.


148
The present system differs from this approach in that, while their master document is RST-structured, that structure is not used as the basis of the pruning, but only to restructure the pieces chosen.


149
Also, the production of sub-documents is intended to produce user-tailored documents, not length-tailored ones.


150
I am aware of work by Veli J.


151
Hakkoymaz (Hakkoymaz in-preparation; Hakkoymaz\&Ozsoyoglu 1996) on Variable-Length Multimedia Presentations, whereby multimedia segments  are added to or dropped from a presentation in order to meet the time constraints.


152
That approach allows substitution of elements as well as deletion, which may be a useful technique.


153
\section{Variable-Length Document Presentation} Any document marked up for RST can be used for variable-length document presentation.


154
This section describes the process whereby the rst-structure is pruned to produce a suitable length document.


155
\subsection{Assigning Relevance Scores to Text Nodes} As described in the introduction, the basic mechanism involves assigning each structural relation a relevance score between 0.0 and 1.0.


156
For instance, \relname{elaboration} may have a score of 0.40 (low relevance), while \relname{purpose} might be scored more highly.


157
By an RST-tree, I assume a tree with the top-nucleus as the root of the tree, and satellites hanging off this, and their satellites hanging off of them.


158
Our task is then to prune branches off of this tree.


159
The top-nucleus has a relevance value of 1.0 (maximum relevance).


160
Through a process of recursive descent, we assign each node in the tree the relevance level of its parent,  multiplied by the relevance score of the relation which connects them to the parent.


161
For instance, an \relname{elaboration} of the top-nucleus would have relevance 0.4 (1.0 * 0.4), while an \relname{elaboration} of that node would have relevance 0.16 (0.4 * 0.4).


162
Nodes lower in the RST-tree (less nuclear) will thus have lower relevance than higher nodes (more nuclear), and will thus be the first to be pruned.


163
This is a simple mechanism, but it has shown good results in producing reasonable texts at whatever degree of verbosity.


164
It is easy to see that an elaboration of an elaboration will in most cases be less essential to a text than the elaboration itself.


165
However, there are some cases where this method breaks down -- nuclearity does not always reflect centrality of information.


166
Sometimes an author introduces information in a rhetorically unimportant place, yet that information may be needed later to understand the argument.


167
One example of this in the summary shown earlier is where the original text had said: {\em he was faced with constant pressure from Edward to sign.


168
He refused to do so}.


169
In the summary, ``to sign'' was pruned as, but it was actually a central concept, and the anaphoric ``so'' failed because of its pruning.


170
The text-nodes are then placed in a queue, position based on their relevance score.


171
\subsection{Pruning the RST-tree} When a request is received to display the text at a particular length, the  system  needs to determine  which  text-nodes to display.


172
Taking each node in  turn from  the relevance queue  (starting  with the most relevant), the program checks to see if  including this text node will push the word-count over  the limit.


173
If not  it adds the node to  the nodes-to-be-expressed list, and increments the words-so-far count.


174
When the word-limit is exceeded, the procedure then turns to expressing the selected nodes.


175
The nodes are expressed in the order in which they appeared in the original full text.


176
Note that the satellites of a node will always have lower or equal relevance than the node itself, so we never include a satellite in the nodes-to-be-expressed list if its nucleus is not, which may produces incoherency.


177
\pagebreak \subsection{Extensions on Basic RST} The RST Markup Tool, and consequently document presentation, allows markup of more than simple nuclear-satellite relations.


178
This includes: \begin{itemize} \negnegspace \item {\bf Multinuclear Relations}: such as \relname{joint} and \relname{sequence}.


179
\negnegspace \item {\bf Schemas}: what are sometimes called ``story grammars'' allowing a sequence of named elements of structure, e.g., \relname{introduction},  \relname{body},  \relname{conclusions}, \relname{bibliography}, etc.


180
\negnegspace \item{\bf Clause-Internal Structure}: for this summarisation work, I have been pushing RST analysis inside the sentence -- not only in terms of analysing the relations between clauses in a sentence, but also analysing the relation between clausal adjuncts and the nuclear clause.


181
For instance, (N: {\em Edward surrendered,})(S: {\em in 1245}).


182
Some of these adjuncts can be connected to the clause with standard RST relations, but many can not.


183
A set of new relations, borrowed from the Systemic labelling of adjuncts (cf.


184
Halliday 1985), has been added for this reason.


185
\end{itemize} \negnegspace Allowing the intermixing of story grammars and RST greatly increases the representative power of the formalism, and subsequently helps in text pruning.


186
For instance, if  we provide the \relname{introduction} and \relname{conclusions} relations  higher relevance values than \relname{body}, then these sections will be more prominent in any summary.


187
All of these structures are handled  in terms of the relation (role) linking the constituent to the whole, and  this relation is handled identically to simple RST relations in text pruning.


188
\subsection{User-Variation of Relation Weightings} The actual values associated with each relation are not fixed, but can be varied by the user.


189
The user can select values which reflect their interests, highlighting some types of rhetorical relations, and ignoring others.


190
The system comes with three inbuilt `user-models', representing different ranges of interest: ({\em standard}, (average values), {\em how\&why} preferring cause, reason, purpose, conditionals, etc., and {\em when\&where}, preferring spatial- and temporal-locations and extents.


191
Figure~\ref{fig:where-when}  demonstrate the slight difference of information (bold font) included in the text when switching between the {\em when\&where} set and the {\em how\&why} set.


192
We might also add such sets as {\em naive}, preferring definitions, clarifications, restatements, and elaborations, while an {\em expert} might value these less, but prefer generalisations, etc.


193
Apart from these built-in values, the user can also assign values to each relation independently.


194
\begin{figure}[b] \rule{\columnwidth}{0.2mm} {\footnotesize {\em How\&Why Summary}: Alexander III, King of Scots, died.


195
The successor to the Scottish throne was his granddaughter Margaret.


196
The earls and other great magnates had accepted Margaret as the heir to the throne and arrangements were made to bring her to Scotland.


197
Several Guardians were appointed {\bf to govern the realm}.


198
Discussions were held with Edward I {\bf to prevent any instability}.


199
A treaty was signed {\bf whereby the new queen was to marry Edward's own son}.


200
Margaret died.


201
Edward brought out his claims of overlordship.


202
{\bf He used the treaty of Falaise}.


203
...} \rule{\columnwidth}{0.2mm} {\footnotesize {\em Where\&When Summary}: {\bf In 1286,} Alexander III, King of Scots, died {\bf at Kinghorn in Fife}.


204
The successor to the Scottish throne was his granddaughter Margaret.


205
The earls and other great magnates had accepted Margaret as the heir {\bf to the throne} and arrangements were made to bring her to Scotland.


206
{\bf In the meantime,} several Guardians were appointed.


207
Discussions were held with Edward I.


208
A treaty was signed.


209
Margaret died {\bf in\Orkney}.


210
{\bf After her death,} Edward brought out his claims of overlordship {\bf of Scotland.} ...} \negspace \caption{Summaries with different weighting sets} \negspace \label{fig:where-when} \rule{\columnwidth}{0.2mm} \negspace \negnegspace \negnegspace \end{figure} \negnegspace \negnegspace \section{Preserving Coherence in Dynamic Document Presentation} \negnegspace When summarising a document, we do damage to various aspects of the document's coherency.


211
These aspects will be covered below under four topics: paragraphing, punctuation, referring expressions and discourse markers.


212
\negnegspace \subsection{Paragraphing} \negnegspace Deleting sentences without changing paragraph boundaries would produce a text of many short paragraphs, reducing readability.


213
Rather than attempt to repair document paragraphing, we have found it easier to throw away the original paragraphing, and re-determine paragraph boundaries as described below.


214
Paragraphing within a document is intended\to make it easier to read.


215
It segments the discourse into small chunks of sentences which are to some degree highly related.


216
We found it plausible to use our RST structure to help in determining paragraph boundaries.


217
From looking at texts, it is the usual case to see a paragraph representing a nucleus and its satellites (although some other of its satellites be in other paragraphs).


218
There is a useful notion used in speech synthesis and generation which claims that the spacing between spoken words can be predicted largely by the {\em syntactic distance} between them -- the number of branches which have to be traversed in the parse tree to move from one word to the other.


219
Thus, in {\em the Girl Guides fish}, we would expect little pause between noun {\em Guides} and its modifier {\em Girl}, while in the homophone {\em the girl guides fish} we would expect more pause between the verb {\em guides} and the subject {\em girl}.


220
We have applied this principle to paragraphing, arguing that two adjacent sentences which are more discoursally distant (more structurally separated in terms of the RST-tree)  are more likely to be separated by a paragraph break.\footnote{An alternative approach might evaluate potential paragraph breaks on the basis of the {\em number} of nucleus-satellite links that boundary breaks compared to other possible breaks.


221
This approach would reward paragraphs which are sub-trees of the RST.


222
In addition, we might penalise what we might call {\em foster} sentences -- sentences  which have no direct relation to the other sentences in that paragraph.} This is not the whole story however.


223
Paragraphing is also constrained by the needs of {\em paragraphic rhythm}.


224
Martinec (1995) argues that the division of texts into paragraphs is similar to the rhythmic structure of the sentence (divided into tonic feet of similar interval).


225
Both are means of organising information into manageable chunks.


226
The {\em rhythm} of a text requires that these chunks are of approximately the same size, not too long, not too short.


227
Our paragraphing algorithm combines these two notions -- semantic distance and paragraphic rhythm -- to determine paragraph boundaries in the presented texts.


228
We assume there is an ``ideal'' paragraph length for the text, the paragraph rhythm (user configurable).


229
Starting at the beginning of the text, we test each point between sentences for a possible paragraph-break.


230
We evaluate two factors: \begin{enumerate} \negnegspace \item {\bf Semantic Distance}: how many arcs of the RST-tree do we need to traverse to get from one sentence to the other.


231
In a sense, we are looking for the weak-points in the text, textually adjacent sentences which are not semantically closely related.


232
\negnegspace \item {\bf Projected Paragraph Size}: how much smaller or larger than our ideal would the paragraph be if we broke the paragraph at that point.


233
\negnegspace \end{enumerate} We use the following formula to evaluate each possible paragraph break, and select the point with the lowest value (I will leave fuller explanation to a paper dedicated to the topic): \negnegspace \[Score(N_i,N_{i+1}) = (ideal\_length - actual\_length)^{j} + \frac{k}{sem\_dist(N_i,N_{i+1})} \] ...where ideal\_length, {\em j} and {\em k} are constants.


234
I have found best results with values of 150, 1.2 and 75.


235
Lower values of j allow more variation of paragraph size in seeking for better breaks on semantic distance grounds.


236
Once a paragraph position is selected, we take that as our starting point and look for the next paragraph boundary after that, until the end of the text is reached.


237
As you can see from figures 1 and 2 (both paragraphed using the above formula), the method produces quite plausible paragraphing.


238
\subsection{Punctuation} As reported above, we have allowed the RST Tool to assign structure {\em within} the sentence as well as {\em between} sentences.


239
This however creates a problem because, in deleting an intra-sentence nucleus, we may also delete the punctuation it carries.


240
For instance, in (N: {\em Edward surrendered,})(S: {\em in 1245}), deletion of the nucleus leaves us with a sentence terminated by a comma.


241
One module of the present system has been developed to correct such problems.


242
It ensures all sentences start with a capital, and recovers the sentence-terminating punctuation from any pruned segments where necessary.


243
\subsection{Referring Expressions} When deleting sections of a text, we may destroy the referential cohesion of a text in two ways.


244
Firstly, we might delete the introduction of an entity, which provided the entities name, or other characteristics which allow the reader to identify the entity correctly.


245
The remaining text may refer to this entity (e.g., ``he''), but leave no clue as to who the entity is.


246
The second, related, problem involves changing the referential environment of entities.


247
References which are contextually unambiguous in the full text may be brought into close proximity to other entities which are potential confusers.


248
In the system as implemented so far, there has been no attempt to correct these problems.


249
Cases of problems have been rare.


250
However, for the next stage of implementation we are planning to introduce NP markup into the document preparation stage, allowing the document editor to indicate co-reference of NPs in the text.


251
This would be a simple matter of allowing the editor to drag from each NP to a co-referring NP.


252
From this markup, we can deduce various things.


253
We can identify the first-occurring reference for each entity, and with a reasonable level of certainty, use this as the first-mention of the entity in any pruned-text.


254
We can analyse the remaining references to discover gender (from pronouns) or class (from definite or indefinite references).


255
Where text-pruning places two entities of similar gender in proximity, the class-based or name-based reference form could be used if available.


256
In this way, many of the reference problems can be repaired.


257
An anaphora generation module being developed by Janet Hitzeman is a good candidate for use here.


258
The extra cost of NP markup needs to be weighed against the gain of coherency gained.


259
\subsection{Discourse Markers} Markers of rhetorical relations are usually attached to satellites, and so there is no problem when the satellite is pruned.


260
However, in some peoples analyses, some relations mark the nucleus, not the satellite.


261
In others, both the nucleus and satellite are marked (e.g., if/then).


262
When we delete the satellite, we should ensure that the discourse marker is removed also from the nucleus.


263
However, due to the rarity of nucleus marking, this problem rarely occurs.\footnote{In the case of if/then, I have the \relname{ELABORATION} relation set to 100\% relevance, since a clause without its condition has a totally different meaning.} For those cases where nucleus marking does occur, a future applications might avoid the problem by removing all discourse markers from the marked-up text, and generating these as appropriate.


264
However, I envisage problems associated with this approach, including over-generation of discourse linkers (many are left implicit).


265
\pagebreak \section{Document Preparation} Before the text can be used for variable-length presentation, it needs to be marked-up in terms of RST structure.


266
To facilitate this step, we have developed an RST Markup Tool, which allows a user to: \begin{enumerate} \item Segment the text.


267
\item Graphically link these segments together into an RST-tree.


268
\end{enumerate} \subsection{Text Segmentation} Each of these tasks has a separate interface within the tool.


269
The first is shown in figure~\ref{fig:segment}.


270
The buttons ``Sentences'' and ``Paragraphs'' result in automatic recognition of sentence and paragraph boundaries.


271
If further segmentation is required, the user can switch into {\em segmentation} mode, during which they need only click at each segment boundary to introduce a segmentation marker.


272
To edit the text (modifying the text,  correcting spelling errors, etc.), switch to the {\em Edit} mode.


273
\begin{figure*} \begin{center} \epsfxsize=5.5in \leavevmode % force centering \epsfbox{segment.eps} \negnegspace \negnegspace \caption{Text Segmentation Tool} \negnegspace \negnegspace \label{fig:segment} \end{center} \end{figure*} A  problem occurs with {\em embedded elements} -- cases where a rhetorically dependent stretch of text occurs within another node.


274
For instance, we might wish to treat the embedded clause in the following as dependent on the main clause: {\em John, -- I think you know him -- is here for two weeks.} At present, the interface does not handle such cases.


275
A simple solution is for the user to move the embedded text outside of the enclosing text.


276
\subsection{Text Structuring} The second step of document preparation involves structuring the text.


277
Another interface of the RST Markup Tool allows the user to connect the segments into a rhetorical structure tree, as shown in figure~\ref{fig:structure}.


278
We have followed the graphical style presented in Mann \& Thompson (1987).


279
\begin{figure*} \begin{center} \epsfxsize=5.5in \leavevmode % force centering \epsfbox{rstedit.eps} \negnegspace \negnegspace \caption{Text Structuring Tool} \negnegspace \negnegspace \label{fig:structure} \end{center} \end{figure*} Initially, all segments are unconnected, ordered at the top of the window.


280
The user can then drag the mouse from one segment (the nucleus) to another (the satellite).


281
Upon releasing the mouse button, the system offers a menu of relations to choose from (the user can use the relation-sets provided with the system, or provide their own).


282
The system allows both plain rst-relations and also multi-nuclear relations (e.g., joint, sequence, etc.).


283
Scoping is also possible, whereby the user indicates that the nucleus of a relation is not a segment itself, but rather a segment and its satellites.


284
See figure~\ref{fig:example} for an example of both a multi-nuclear structure, and scoping.


285
In addition, McKeon-style {\em schemas} (sometimes called {\em story-grammars}) can be used to represent constituency-type structures.


286
See figure~\ref{fig:joke}.


287
\begin{figure} \begin{center} \epsfxsize=3.9in \leavevmode % force centering \epsfbox{example.eps} \negnegspace \negnegspace \caption{Scoping and multi-nuclear relations} \negnegspace \negnegspace \label{fig:example} \end{center} \end{figure} \begin{figure} \begin{center} \epsfxsize=3.9in \leavevmode % force centering \epsfbox{joke.eps} \negnegspace \negnegspace \caption{Constituent Structure} \negnegspace \negnegspace \label{fig:joke} \end{center} \end{figure} The user can switch freely between text segmentation and text structuring mode -- to edit text, or to change segment boundaries.


288
The system keeps track of the structure assigned so far.


289
If the user, in editing the text, deletes a segment, the system forgets structuring information concerning that segment.


290
Because rst-structures can become very elaborate, the RST Tool allows the user to {\em collapse} sub-trees -- hiding the substructure under a node, This makes it easier, for instance, to connect two nodes which normally would not appear on the same page of the editor.


291
The user can save the present state of the screen as postscript, for inclusion in Latex documents.


292
Alternatively, a snapshot utility can be used to save selected parts of the structure in other formats.


293
The structured text can be saved to a file, for later re-editing, or for use in variable-length document presentation.


294
\pagebreak \section{Summary} This paper has described a system for presenting variable-length on-line documentation, which allows the user to select the degree of verbosity of the text presented.


295
The results so far on a small-scale have shown that reasonable-quality texts can be produced dynamically.


296
The cost of document markup stops this approach being used on texts of short display-life, but makes it economical for documents of longer duration where length-variability has value.


297
Apart from text-length, Variable-Length documents allow the user a small degree of content-control, to the degree that they can determine the relevance of each RST relation (or of elements of a schema).


298
The major problem for the system involves restoring coherence after text-pruning, particularly in areas of reference, discourse markers, paragraphing and punctuation.


299
The problems of paragraphing and punctuation have been solved, and solutions are suggested for the other two areas.


300
Another problem occurs when material important to the text is not included in nuclear positions in the RST-tree: nuclearity does not guarantee importance to discourse goals (although there is a strong correlation between nuclearity and importance).


301
This is why, in the long term, approaches such as Rino\&Scott (1996), which take intentional structure as well into account show some promise.


302
While information about intention structure is not easy to mark up, it would be available in a system doing full text generation from intentions.


303
Regardless of the problems of this approach, the system is up and running on-line.


304
New documents are being added as time allows, to test the generalisability of the approach.


305
Future development will include features  such as allowing the user to zoom in on text by clicking on it.


306
I will soon make sentence punctuation hyper-clickable, which would result in the pruned text under that sentence being provided.


307
The notion of variable length on-line documents has great value to information providers and information readers alike -- imagine if this document had been provided variable-length, you could have read the two page version instead!


308
\section{Bibliography} \negnegspace \negnegspace \setlength{\parindent}{0in} \setlength{\parskip}{0.05in} {\small DiMarco, Chrysanne; Graeme Hirst, Leo Wanner \& John Wilkinson 1995.


309
``HealthDoc: Customizing patient information and health education by medical condition and personal characteristics''.


310
Workshop on Artificial Intelligence in Patient Education, Glasgow, August 1995.


311
Hakkoymaz, Veli J.


312
(in prep) ``Organizing Variable-Length Multimedia Presentations within a Given Deadline''.


313
Hakkoymaz, Veli J. & Gultekin Ozsoyoglu 1996 ``Automating the Organization of Presentations for Playout Management in Multimedia Databases".


314
IEEE Int'l Workshop on Multi-Media Database Management Systems, Aug. 1996.


315
Halliday, M.A.K.


316
1985 {\em Introduction to Functional Grammar}.


317
London: Edward Arnold.


318
Mann, William C. & Sandra Thompson, 1987.


319
``Rhetorical Structure Theory: A Theory of Text Organization".


320
Technical Report ISI/RS-87-190.


321
Martinec, Radan 1995 {\em Hierarchy of Rhythm in English Speech}, Ph.D. dissertation.


322
Dept. of Semiotics, University of Sydney.


323
Rino, L.H.M. & Scott, D.R.


324
1996 ``A Discourse Model for Gist Preservation''.


325
In Dibio L. Borges and Celso A.A. Kaestner (eds.), Advances in Artificial Intelligence (Proceedings of the 13th Brazilian Symposium on Artificial Intelligence), pp. 131-140.


326
Springer-Verlag, Germany.


327
Sparck Jones, Karen.


328
1993.


329
``What might be in a summary?", Information Retrieval 93: Von der Modellierung zur Anwendung (Ed. Knorz, Krause and Womser-Hacker), Konstanz: Universitatsverlag Konstanz), 9-26.


330
\end{document}


331
constit


332
span
331
Abstract
333
span
4
Elaboration
334
span
6
Method
335
span
8
Re-state
336
span
9
Purpose
337
span
4
Elaboration
338
span
13
Elaboration
339
span
13
Comment
340
constit


341
span
342
span
342
span
340
Point
343
span
341
Counter-Expectation
344
multinuc
22
Detail
345
span
22
Detail
346
span
340
Point
347
multinuc
28
Detail
348
span
347
Sequence
349
span
340
Point
350
span
33
medium
351
span
352
span
352
span
33
high
353
span
37
Comment
354
span
38
Counter-Expectation
355
constit
33
essential
356
constit
351
essential
357
span
45
essential
358
span
47
Particularise
359
span
47
Method
360
span
51
Comment
361
span
45
essential
362
span
55
Particularise
363
span
56
Detail
364
span
340
Point
365
span
61
Matter
366
span
65
Result
367
multinuc
340
Point
368
span
367
Sequence
369
multinuc
368
Detail
370
span
371
span
371
span
367
Sequence
372
span
91
Elaboration
373
span
92
high
374
span
385
span
375
span
340
Point
376
span
364
Re-state
377
span
380
span
378
span
379
span
379
span
377
Detail
380
span
340
Point
381
span
382
Sequence
382
multinuc
340
Point
383
span
85
Elaboration
384
span
382
Sequence
385
span
91
Background
386
span
98
Concession
387
span
91
Background
388
span
99
Concession
389
span
105
medium
390
span
382
Sequence
392
constit


393
span
115
Matter
394
constit


395
span
132
Concession
397
span
394
Point
399
multinuc
128
Reason
400
span
401
span
401
span
126
Evidence
402
span
125
Evidence
