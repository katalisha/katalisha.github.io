---
layout: post
title: ARC, Swift closures and weak self
---
<img src="/images/fulls/swallowed_a_fly.jpg" class="fit image">
A commonly misunderstood/unknown feature of Swift closures is the *closure capture list*. It tells a closure how strongly to capture variables from the surrounding scope. This is useful in avoiding strong reference cycles which can prevent memory being freed when it's no longer needed - a memory leak.

Let's start by explaining how strong reference cycles happen and why they're bad.

Automatic Reference Counting (ARC)
----------------------------------
iOS uses reference counting to determine when a reference type is no longer in use and it's memory can be freed.
It's a fairly simple concept - when a reference is assigned to property, constant or variable it's retain count is incremented.
When the property, constant or variable moves out of scope the retain count of the references is decremented.
When the retain count is 0 the reference is no longer in use and the memory can be freed.

<table>
<tr>
<th>Action</th>
<th>Retain Count</th>
</tr>
<tr>
<td><code>var a = MyReferenceType()</code></td>
<td>1</td>
</tr>
<tr>
<td><code>var b = a</code></td>
<td>2</td>
</tr>
<tr>
<td>b out of scope</td>
<td>1</td>
</tr>
<tr>
<td>a out of scope</td>
<td>0💥</td>
</tr>
</table>

Strong Reference Cycles
-----------------------
One drawback of ARC is that it's possible to create a strong reference cycle, where two objects refer to each other - making it impossible for their retain counts to reach 0.

<table>
<tr>
<th>Action</th>
<th>Ref 1 retain count</th>
<th>Ref 2 retain count</th>
</tr>
<tr>
<td><code>var a = MyReferenceType() // Ref 1</code></td>
<td>1</td>
<td>0</td>
</tr>
<tr>
<td><code>var b = MyReferenceType() // Ref 2</code></td>
<td>1</td>
<td>1</td>
</tr>
<tr>
<td><code>a.ref = b</code></td>
<td>1</td>
<td>2</td>
</tr>
<tr>
<td><code>b.ref = a</code></td>
<td>2</td>
<td>2</td>
</tr>
<tr>
<td>a out of scope</td>
<td>1</td>
<td>2</td>
</tr>
<tr>
<td>b out of scope</td>
<td>1</td>
<td>1</td>
</tr>
</table>

At the end of this example both objects hold a strong reference to each other so they cannot be destroyed, even though they are no longer in scope.

Weak and unowned references
---------------------------
When it's necessary to have to two objects reference one another the solution is to use weak and unowned references. These kinds of references do not increment the retain count. So if the `MyReferenceType.ref` property above were declared as weak, the retain counts would work like this:
<table>
<tr>
<th>Action</th>
<th>Ref 1 retain count</th>
<th>Ref 2 retain count</th>
</tr>
<tr>
<td><code>var a = MyReferenceType() // Ref 1</code></td>
<td>1</td>
<td>0</td>
</tr>
<tr>
<td><code>var b = MyReferenceType() // Ref 2</code></td>
<td>1</td>
<td>1</td>
</tr>
<tr>
<td><code>a.ref = b</code></td>
<td>1</td>
<td>1</td>
</tr>
<tr>
<td><code>b.ref = a</code></td>
<td>1</td>
<td>1</td>
</tr>
<tr>
<td>a out of scope</td>
<td>0💥</td>
<td>1</td>
</tr>
<tr>
<td>b out of scope</td>
<td></td>
<td>0💥</td>
</tr>
</table>

The memory is freed. However weak and unowned references should be used with care. This example highlights the they complexity introduce - Ref 1 has been freed while Ref 2 was using it. Thought needs to be put in to the design for how to handle this possibility.

You can read more about ARC and weak and unowned references [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html).

Reference Cycles in Closures
----------------------------
Examples of strong reference cycles in documentation tend to be fairly contrived and it's pretty easy to see when bad composition could create one. However Swift closures and their ability to automatically capture surrounding scope, make it harder to spot any reference cycles accidentally created this way.

There are two kinds of closures we're concerned about - nested functions and closure expressions (yes nested functions are closures too!)

The things to watch out for are:

1. Closures that captures self. This can happen by using an instance property or instance method within a closure; and
2. The possibility of the closure being assigned to a property of self (either directly or by being assigned to a child of self)

A very common example of these two things occurs when using disposables in [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa).

    import ReactiveCocoa

    class Thing {
      var disposable:Disposable?
      var total:Int = 0

      deinit {
        disposable?.dispose()
      }

      init(producer:SignalProducer<Int,NoError>) {
        disposable = producer.startWithNext{number in
          self.total += number
          print(self.total)
        }
      }
    }

In this example the closure captures self through the use of the `total` property. This adds to self's retain count.
This is ok so long as it is possible for the closure's own retain count can reach 0, releasing self and allowing it to be destroyed.
The problem occurs when a reference to the closure is kept by the disposable property.
This creates the cycle - the closure can't release self util self releases the closure.

Closure Capture Lists
---------------------------
Closure expressions provide a *closure capture list* to change the strength of these references

    disposable = producer.startWithNext{[weak self] number in
      self?.total += number
      print(self?.total)
    }

In this example self is not retained by the closure - it's retain count will not be incremented by closure capturing it and no cycle is created.

What about nested functions?
----------------------------
Nested functions are slightly more verbose, requiring the weak/unowned variable to be created in the outer function, then captured by the nested function.

    func outer() {
      weak var this = self
      func inner() {
        this.number += 1
      }
    }

In this example when `self` is weakly assigned to `this` it does not increment self's retain count. The closure captures `this` instead of `self` so it doesn't increment the retain count on `self` either.
Remember you only need a weak reference if the nested function is assigned to a property on self, which doesn't actually happen in this snippet.

What's the point?
-----------------
There is a temptation to add weak self to the capture closure list everytime. This will always avoid a possible memory leak but can add complexity and unexpected behaviour in certain cases. Also look out for nested functions which are closures in disguise.

You must use weak/unowned references if:

1. Closures that captures self. This can happen by using an instance property or instance method within a closure; and
2. The possibility of the closure being assigned to a property of self (either directly or by being assigned to a child of self)

Show Me Some code!
----------
I've created a [playground](https://github.com/katalisha/weak-self-examples) with a few examples of strong reference cycles and closures.
