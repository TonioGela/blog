+++
title = "Scala 3 in pillole: Extension Methods"
date = 2021-06-12
language="it"
draft=true
[extra]
description = "Affrontiamo un argomento molto semplice: gli extension methods di scala 3, o per meglio dire, la nuova sintassi per gli extension methods in Scala. Primo post in italiano e primo post su Scala 3."
+++

**Premessa**: se questo post non vi dovesse piacere, nel caso in cui il mio italiano scritto fosse pietoso (probabilità > 90%), se leggere di Scala in italiano vi sembrasse inutile o noioso, sappiate che:

- non mi interessa
- maschero la mia insicurezza nello scrivere aggiungendo un sacco di sarcasmo e <strike>stronzate</strike> battute nei post
- non mi interessa
- è stata tutta un'idea di [@mfirry](https://twitter.com/mfirry), quindi incolpate lui :heart:.

---

Soprendentemente se parlerò di Scala a partire da giugno 2021 parleró di Scala 3. Era infatti il 13 maggio quando scrivevo su {{ resize_image(path="pages/about_me/slack.png", width=15, height=15, op="fit") }} [Scala Italy](https://scalaitaly.slack.com)

{{ centered(path="annuncio.png") }}

una notizia che apparentemente ha rallegrato gli animi di almeno 7 persone. Dopo [8 lunghi anni](https://www.scala-lang.org/blog/2021/05/14/scala3-is-here.html) di attesa possiamo finalmente (tra le altre cose) creare e usare **extension methods** a nostro piacimento senza dover creare (manualmente) delle classi implicite che `incapsulano` la classe originale.

Nonostante mi venga fatto notare quasi quotidianamente che abuso di parole anglosassoni, ci tengo a dire che la scelta di non tradurre determinati termini tecnici mi è sembrata doverosa. Un'italianizzazione di nomi quali `extension methods` appare un po' forzata e produce risultati dal sapore decisamente _vintage_.

{{ center_into(path="metodi_estesivi.png", width=550) }}

Parliamo dunque <strike>dei metodi estesivi</strike> degli **extension methods**.

## Extension methods in Scala 2

Come i più di voi, ma forse non tutti, sapranno, Scala oltre ad essere un linguaggio funzionale è anche un linguaggio ad oggetti, quindi esattamente come accade in altri linguaggi ad oggetti, è possibile definire `metodi` all'interno di `classi` per poi poterli richiamare sulle `istanze` di queste ultime. Oppure, in salsa funzionale e prendendomi un'**ENORME** licenza poetica: è possibile definire `funzioni` associate ad un `tipo` per poterle poi richiamare a partire da un `valore` di quello specifico tipo (se definite in una `classe`) o a partire dal tipo stesso (se definite in un `object`).

{% codeBlock(title="Person (Scala 2)") %}
```scala mdoc
class Person(val name: String) {
   def present(): Unit = println(s"Hello I'm ${name}")
}

val galileo = new Person("Galileo")

galileo.present()
```
{% end %}

Finora nulla di complicato né di nuovo; se abbiamo bisogno di una funzione da poter chiamare su un un tipo `T` o su un valore `t` di tipo `T` possiamo definirla rispettivamente in `object T` o in `class T` e accedervi tramite `.`.

Tuttavia nel caso in cui il tipo di cui stiamo creando un valore non fosse definito _all'interno della nostra codebase_ ma fosse, ad esempio, una definizione proveniente da una **libreria**, associare una nuova funzione in questa maniera ci sarebbe impossibile. 

{% quote() %}
A dir la verità, nel caso in cui una definizione di tipo fosse all'interno della nostra codebase e fosse molto "__endemica__" alterarne la firma sarebbe sicuramente un'operazione da affrontare con molta cautela. Una modifica non retrocompatibile alla definizione di quel tipo ci costringerebbe a molte "fix" puntuali in tutti i vari siti di chiamata. Ma questo è [OOP](https://it.wikipedia.org/wiki/Programmazione_orientata_agli_oggetti), non devo/voglio insegnarlo e ad ogni modo dal '95 esiste il [Gang of Four](https://it.wikipedia.org/wiki/Design_Patterns).
{% end %}

La maniera canonica di incapsulare della business logic che necessita di un valore `T`, qualora noi non si possa accedere alla definizione di `T` per poterla modificare, è quella di creare una funzione che abbia tra i suoi parametri anche `T`.

{% codeBlock(title="Static Method (Scala 2)") %}
```scala mdoc
object Person {
   def presentWithDetails(p: Person, details:String): Unit = {
      println(s"Hello, I'm ${p.name} ${details}")
   }
}

Person.presentWithDetails(galileo, "and I'm very glad to meet you.")
```
{% end %}

Tuttavia questa metodologia, in virtù del fatto che la funzione va chiamata staticamente sull'oggetto `Person`, può portare alla lunga ad avere codice difficile da leggere e/o da mantenere: le alternative sono solo quella di usare `import Person._` per importare staticamente tutte le funzioni definite in quell'oggetto (per domandarsi in un secondo momento "dove accidenti l'ho definita la funzione `presentWithDetails`?") o quella di invocarla "_namespaced_" anteponendo il nome dell'oggetto che ne contiene la definizione.

Se ci fosse necessità di chiamare la funzione esplicitamente un numero consistente di volte (dove la definizione di "consistente" è legata al gusto personale) in Scala 2 è possibile decidere di _scrivere_ un po' di boilerplate per poterne utilizzare meno in fase di chiamata. Possiamo definire una `implicit class` 

{% codeBlock(title="PersonSyntax (Scala 2)") %}
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


che è possibile importare ovunque si voglia utilizzare la nuova "**sintassi**".

```scala mdoc:invisible:reset-object
class Person(val name: String) {
   def present(): Unit = println(s"Hello I'm ${name}")
}

val galileo = new Person("Galileo")

object Person {
   implicit class PersonSyntax(private val p:Person) extends AnyVal {
      def presentWithDetails(details:String): Unit = {
         println(s"Hello, I'm ${p.name} ${details}")
      }
   }
}
```

{% codeBlock(title="PersonSyntax usage (Scala 2)") %}
```scala mdoc
import Person.PersonSyntax

galileo.presentWithDetails("and I'm very glad to meet you.")
```
{% end %}

Notare che nel boilerplate è consigliato rendere il parametro del costruttore privato e per evitare allocazioni inutili [quasi sempre](https://docs.scala-lang.org/overviews/core/value-classes.html#when-allocation-is-necessary) rendere la classe una value class, entrambe cose di cui ci si può scordare.

In Scala 2 le implicit class sono utilizzate da sempre per legare, tramite "sintassi", ad un tipo delle funzionalità aggiuntive definite nell'istanza di una `typeclass` per quel determinato tipo. Un esempio è la typeclass `Show`:

```scala mdoc:invisible
import scala.language.postfixOps
```

{% codeBlock(title="Show Typeclass (Scala 2)") %}
```scala mdoc
trait Show[A] {
   def show(x: A): String
}

object Show {
   def apply[T](implicit s: Show[T]): Show[T] = s

   implicit class ShowSyntax[T](private val a: T) extends AnyVal {
      def !(implicit s: Show[T]): String = Show[T].show(a)
   }
}

implicit val showInt: Show[Int] = new Show[Int] {
   def show(x: Int): String = s"${x}"
}

import Show._

1!

(1 + 2 + 3)!

(1!) + (2!) + (3!)
```
{% end %}

In questo caso, sia la dipendenza implicita da `Show[T]` che l'effettiva chiamata a funzione `Show[T].show` sono "nascoste" in una classe implicita, ma possiamo accedervi utilizzando il metodo `!` direttamente sull'istanza di `T` se in scope abbiamo un'istanza di `Show[T]`.

Vista <strike>l'enorme</strike> la quantità di codice necessario a definirle, per Scala 2 è stato creato  [simulacrum](https://github.com/typelevel/simulacrum) un compiler plugin che tramite macro che permette di ridurre la quantità di <strike>[lamiera per caldaie](https://www.wordreference.com/enit/boilerplate)</strike> boilerplate richiesto.

{% codeBlock(title="Show Typeclass with Simulacrum (Scala 2)") %}
```scala
import simulacrum._

@typeclass trait Show[A] {
   @op("!") def show(x: A): String
}

// Stessa identica implementazione
implicit val showInt: Show[Int] = new Show[Int] {
   def show(x: Int): String = s"${x}"
}
// showInt: Show[Int] = repl.MdocSession$App2$$anon$1@67b0e209

import Show.ops._

1!
// res7: String = "1"

(1 + 2 + 3)!
// res8: String = "6"

(1!) + (2!) + (3!)
// res9: String = "123"
```
{% end %}

:tada: **Momento auto-promozione** :tada: Per chi non lo sapesse ho fatto un [talk sulle typeclasses](https://youtu.be/nBeXGEpDgdk) in italiano.

## Extension methods in Scala 3

Cita documentazione https://dotty.epfl.ch/docs/reference/contextual/extension-methods.html

{% codeBlock(title="This code will be in Scala 3", color="blue") %}
```scala3
case class Circle(x: Double, y: Double, radius: Double)

extension (c: Circle)
  def circumference: Double = c.radius * math.Pi * 2
```
{% end %}

{% codeBlock(title="This code will be in Scala 3", color="green") %}
```scala3
case class Circle(x: Double, y: Double, radius: Double)

extension (c: Circle)
  def circumference: Double = c.radius * math.Pi * 2
```
{% end %}

{% codeBlock(title="This code will be in Scala 3", color="yellow") %}
```scala3
case class Circle(x: Double, y: Double, radius: Double)

extension (c: Circle)
  def circumference: Double = c.radius * math.Pi * 2
```
{% end %}