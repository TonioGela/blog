+++
title = "Scala 3 in pillole: Extension Methods"
date = 2021-06-11
language="it"
draft=true
[extra]
description = "Affrontiamo un argomento molto semplice: gli extension methods di scala 3, o per meglio dire, la nuova sintassi per gli extension methods in Scala. Primo post in italiano e primo post su Scala 3."
+++

**Premessa**: se questo post non vi dovesse piacere, se scrivessi da schifo in italiano (probabilità > 90%), se leggere di Scala in italiano vi sembrasse inutile o noioso, sappiate che:

- non mi interessa
- maschero la mia insicurezza nello scrivere in italiano aggiungendo un sacco di sarcasmo e battute nei post
- non mi interessa
- é stata tutta un'idea di [@mfirry](https://twitter.com/mfirry), quindi incolpate lui :heart:.

---

Soprendentemente se parlerò di Scala a partire da giugno 2021 parleró di Scala 3. Era infatti il 13 maggio quando shitpostavo su {{ resize_image(path="pages/about_me/slack.png", width=15, height=15, op="fit") }} [Scala Italy](https://scalaitaly.slack.com)

{{ centered(path="annuncio.png") }}

una notizia che apparentemente ha rallegrato gli animi di almeno 7 persone. Dopo [8 lunghi anni](https://www.scala-lang.org/blog/2021/05/14/scala3-is-here.html) di attesa possiamo finalmente (tra le altre cose) creare e usare **extension methods** a nostro piacimento senza dover creare (manualmente) delle classi implicite che _wrappano_ (`sondaggio: come si traduce in italiano?`) la classe originale.



## Extension methods in Scala 2

Come i più di voi, ma non tutti, sapranno, Scala oltre ad essere un linguaggio funzionale (haskeller muti) é anche un linguaggio ad oggetti, quindi esattamente come accade in altri linguaggi ad oggetti, é possibile definire `metodi` all'interno di `classi` per poi poterli richiamare sulle `istanze` di queste ultime. Oppure, in salsa funzionale e prendendomi molte licenze poetiche, é possibile definire `funzioni` associate ad un `tipo` per poterle poi richiamare a partire da un `valore` di quello specifico tipo (se definite in una `classe`) o a partire dal tipo stesso (se definite in un `object`).

```scala3
class Person(val name: String) {
   def present(): Unit = println(s"Hello I'm ${name}")
}

val galileo = new Person("Galileo")

galileo.present()
// "Hello I'm Galileo"
```

Fin'ora nulla di complicato né di nuovo; se abbiamo bisogno di una funzione da poter chiamare su un un tipo `T` o su un valore `t` di tipo `T` possiamo definirla rispettivamente in `object T` o in `class T`.

Tuttavia nel caso in cui il tipo di cui stiamo creando un valore non fosse definito _all'interno della nostra codebase_ ma fosse, ad esempio, una definizione proveniente da una libreria, associare una nuova funzione in questa maniera ci sarebbe impossibile. 

Anzi, a dir la verità, nel caso in cui una definizione di tipo fosse all'interno della nostra codebase e fosse molto "__endemica__" alterarne la firma sarebbe sicuramente un'operazione da affrontare con molta cautela. Una modifica non retrocompatibile alla definizione di quel tipo ci costringerebbe a molte "fix" puntuali in tutti i vari siti di chiamata.