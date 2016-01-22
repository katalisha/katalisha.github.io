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
It's a fairly simple concept: when a reference assigned to property, constant or variable it's retain count is incremented.
When the property, constant or variable is deallocated the retain count is decremented.
When the retain count is 0 the reference can be safely removed.

<table>
<tr>
<th>Action</th>
<th>`var a = MyReferenceType()`</th>
<th>`var b = a`</th>
<th>b deinitialised</th>
<th>a deinitialised</th>
</tr>
<tr>
<td>Retain Count</td>
<td>1</td>
<td>2</td>
<td>1</td>
<td>0💥</td>
</tr>
</table>

Strong Reference Cycles
-----------------------
One drawback of ARC is that it's possible to create a strong reference cycle, where two objects reference each other - making it impossible for their retain counts to reach 0.

<table>
<tr>
<th>Action</th>
<th>`var a = MyReferenceType()`</th>
<th>`var b = MyReferenceType()`</th>
<th>`a.ref = b`</th>
<th>`b.ref = a`</th>
<th>a deinitialised</th>
<th>b deinitialised</th>
</tr>
<tr>
<td>Object A retain count</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>2</td>
<td>1</td>
</td>1</td>
</tr>
<tr>
<td>Object B retain count</td>
<td>0</td>
<td>1</td>
<td>2</td>
<td>2</td>
<td>2</td>
<td>1</td>
</tr>
</table>

At the end of this example both objects hold a strong reference to each other so they cannot be destroyed. Even though they are no longer in use.

Weak and unowned references
---------------------------
When it's necessary to have to two objects reference one another the solution is weak and unowned references. These kinds of references do not increment the retain count. So if the `MyReferenceType.ref` property above were declared as weak, the retain counts would work like this:
<table>
<tr>
<th>Action</th>
<th>`var a = MyReferenceType()`</th>
<th>`var b = MyReferenceType()`</th>
<th>`a.ref = b`</th>
<th>`b.ref = a`</th>
<th>a deinitialised</th>
<th>b deinitialised</th>
</tr>
<tr>
<td>Object A retain count</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>0💥</td>
</td></td>
</tr>
<tr>
<td>Object B retain count</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>0💥</td>
</tr>
</table>

You can read more about ARC and weak and unowned references [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html).

Reference Cycles in Closures
----------------------------
Examples of strong reference cycles in documentation tend to be fairly contrived and it's pretty easy to see when bad composition could create one. However Swift closures and their ability to automatically capture surrounding scope, make it difficult to spot any reference cycles accidentally created this way.

There are two kinds of closures we're concerned about - nested functions and closure expressions (yes nested functions are closure too!)

The things to watch out for are:

1. closures that captures self. This can happen by using an instance property or instance method within a closure; and
2. the possibility of the closure being assigned to a property of self (either directly or by being assigned to a child of self)

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

What about nested functions?
----------------------------
Nested functions are slightly more verbose, requiring the weak/unowned variable to be created in the outer function, then captured by the nested function.

    func outer() {
      weak var this = self
      func inner() {
        this.number += 1
      }
    }

Remember you only need weak self if the nested function is assigned to a property on self, which doesn't happen in this snippet.


More about closures [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html).
