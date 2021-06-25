+++
title = "Scala 3 in pillole: Extension Methods"
date = 2021-06-12
language="it"
draft=true
[extra]
description = "Affrontiamo un argomento molto semplice: gli extension methods di scala 3, o per meglio dire, la nuova sintassi per gli extension methods in Scala. Primo post in italiano e primo post su Scala 3."
+++

**Premessa**: se questo post non vi dovesse piacere, se scrivessi da schifo in italiano (probabilità > 90%), se leggere di Scala in italiano vi sembrasse inutile o noioso, sappiate che:

- non mi interessa
- maschero la mia insicurezza nello scrivere aggiungendo un sacco di sarcasmo e <strike>stronzate</strike> battute nei post
- non mi interessa
- é stata tutta un'idea di [@mfirry](https://twitter.com/mfirry), quindi incolpate lui :heart:.

---

Soprendentemente se parlerò di Scala a partire da giugno 2021 parleró di Scala 3. Era infatti il 13 maggio quando shitpostavo su {{ resize_image(path="pages/about_me/slack.png", width=15, height=15, op="fit") }} [Scala Italy](https://scalaitaly.slack.com)

{{ centered(path="annuncio.png") }}

una notizia che apparentemente ha rallegrato gli animi di almeno 7 persone. Dopo [8 lunghi anni](https://www.scala-lang.org/blog/2021/05/14/scala3-is-here.html) di attesa possiamo finalmente (tra le altre cose) creare e usare **extension methods** a nostro piacimento senza dover creare (manualmente) delle classi implicite che _wrappano_ (`sondaggio: come si traduce in italiano?`) la classe originale.

Nonostante mi venga notare quasi quotidianamente che abuso di parole anglosassoni, ci tengo a dire che la scelta di non tradurre determinati termini tecnici mi é sembrata doverosa. Un'italianizzazione di nomi quali `extension methods` appare un po' forzata e produce risultati dal sapore decisamente _vintage_.

{{ center_into(path="metodi_estesivi.png", width=550) }}

Ciancio alle bande, parliamo dunque <strike>dei metodi estesivi</strike> degli **extension methods**.

## Extension methods in Scala 2

Come i più di voi, ma forse non tutti, sapranno, Scala oltre ad essere un linguaggio funzionale (haskeller muti) é anche un linguaggio ad oggetti, quindi esattamente come accade in altri linguaggi ad oggetti, é possibile definire `metodi` all'interno di `classi` per poi poterli richiamare sulle `istanze` di queste ultime. Oppure, in salsa funzionale e prendendomi un'**ENORME** licenza poetica: é possibile definire `funzioni` associate ad un `tipo` per poterle poi richiamare a partire da un `valore` di quello specifico tipo (se definite in una `classe`) o a partire dal tipo stesso (se definite in un `object`).

{% codeBlock(title="Scala 2") %}
```scala
class Person(val name: String) {
   def present(): Unit = println(s"Hello I'm ${name}")
}

val galileo = new Person("Galileo")
// galileo: Person = repl.MdocSession$App$Person@2e3f324e

galileo.present()
// Hello I'm Galileo
```
{% end %}

Fin'ora nulla di complicato né di nuovo; se abbiamo bisogno di una funzione da poter chiamare su un un tipo `T` o su un valore `t` di tipo `T` possiamo definirla rispettivamente in `object T` o in `class T` e accedervi tramite `.`.

Tuttavia nel caso in cui il tipo di cui stiamo creando un valore non fosse definito _all'interno della nostra codebase_ ma fosse, ad esempio, una definizione proveniente da una **libreria**, associare una nuova funzione in questa maniera ci sarebbe impossibile. 

{% quote() %}
A dir la verità, nel caso in cui una definizione di tipo fosse all'interno della nostra codebase e fosse molto "__endemica__" alterarne la firma sarebbe sicuramente un'operazione da affrontare con molta cautela. Una modifica non retrocompatibile alla definizione di quel tipo ci costringerebbe a molte "fix" puntuali in tutti i vari siti di chiamata. Ma questo é [OOP](https://it.wikipedia.org/wiki/Programmazione_orientata_agli_oggetti), non devo/voglio insegnarlo e ad ogni modo dal '95 esiste il [Gang of Four](https://it.wikipedia.org/wiki/Design_Patterns).
{% end %}

La maniera canonica di incapsulare della business logic che necessita di un valore `T`, qualora noi non si possa accedere alla definizione di `T` per poterla modificare, é quella di creare una funzione che abbia tra i suoi parametri anche `T`.

{% codeBlock(title="Scala 2") %}
```scala
object Person {
   def presentWithDetails(p: Person, details:String): Unit = {
      println(s"Hello, I'm ${p.name} ${details}")
   }
}

Person.presentWithDetails(galileo, "and I'm very glad to meet you.")
// Hello, I'm Galileo and I'm very glad to meet you.
```
{% end %}

Tuttavia questa metodologia costringe all'utilizzo di un po' di boilerplate visto che la funzione va chiamata staticamente: si può usare `import Person._` per importare tutte le funzioni definite nello stesso oggetto o la si può invocare "_namespaced_" anteponendo il nome dell'oggetto in cui é definita.

Se ci fosse necessità di chiamare la funzione esplicitamente un numero consistente di volte (dove la definizione di "consistente" é legata al gusto personale) in Scala 2 é possibile decidere di _scrivere_ un po' di boilerplate per poterne utilizzare meno in fase di chiamata. Possiamo definire una `implicit class` 

{% codeBlock(title="Scala 2") %}
```scala
object Person {
   implicit class PersonSyntax(private val p:Person) extends AnyVal {
      def presentWithDetails(details:String): Unit = {
         println(s"Hello, I'm ${p.name} ${details}")
      }
   }
}
```
{% end %}


che é possibile importare ovunque si voglia utilizzare la nuova "**sintassi**".


{% codeBlock(title="Scala 2") %}
```scala
import Person.PersonSyntax

galileo.presentWithDetails("and I'm very glad to meet you.")
// Hello, I'm Galileo and I'm very glad to meet you.
```
{% end %}

Notare che nel boilerplate é consigliato rendere il parametro del costruttore privato e per evitare allocazioni inutili [quasi sempre](https://docs.scala-lang.org/overviews/core/value-classes.html#when-allocation-is-necessary) rendere la classe una value class, entrambe cose di cui ci si può scordare.

In Scala 2 le implicit class sono utilizzate da sempre per legare tramite "sintassi" le funzionalità aggiuntive definite nell'istanza di una `typeclass` al tipo stesso. Più semplicemente, nel classico esempio del semigruppo:

{% codeBlock(title="Scala 2") %}
```scala
trait Semigroup[A] {
  def append(x: A, y: A): A
}

object Semigroup {
   def apply[T](implicit s: Semigroup[T]): Semigroup[T] = s

   implicit class SemigroupSyntax[T](private val a: T) extends AnyVal {
      def |+|(b:T)(implicit sg: Semigroup[T]): T = Semigroup[T].append(a, b)
   }
}

implicit val semigroupInt: Semigroup[Int] = new Semigroup[Int] {
  def append(x: Int, y: Int) = x + y
}
// semigroupInt: Semigroup[Int] = repl.MdocSession$App2$$anon$1@4b4a2fa8

import Semigroup._

1 |+| 2
// res4: Int = 3
```
{% end %}

In questo caso, sia la dipendenza implicita da `Semigroup[T]` che l'effettiva chiamata a funzione `Semigroup[T].append` sono "nascoste" in una classe implicita, ma possiamo accedervi utilizzando il metodo `|+|` direttamente sull'istanza di `T` se in scope abbiamo un'istanza di `Semigroup[T]`.

Vista l'enorme quantità di codice necessario a definirle, per Scala 2 é stato creato  [simulacrum](https://github.com/typelevel/simulacrum) un compiler plugin che tramite macro che permette di ridurre la quantità di <strike>[lamiera per caldaie](https://www.wordreference.com/enit/boilerplate)</strike> boilerplate richiesto.

{% codeBlock(title="Scala 2") %}
```scala
import simulacrum._

@typeclass trait Semigroup[A] {
   @op("|+|") def append(x: A, y: A): A
}

implicit val semigroupInt: Semigroup[Int] = new Semigroup[Int] {
   def append(x: Int, y: Int) = x + y
}
// semigroupInt: Semigroup[Int] = repl.MdocSession$App2$$anon$1@414f3fa8

import Semigroup.ops._

1 |+| 2 
// res5: Int = 3
```
{% end %}

:tada: **Momento auto-promozione** :tada: Per chi non lo sapesse ho fatto un [talk sulle typeclasses](https://youtu.be/nBeXGEpDgdk) in italiano.

## Extension methods in Scala 3

Cita documentazione https://dotty.epfl.ch/docs/reference/contextual/extension-methods.html