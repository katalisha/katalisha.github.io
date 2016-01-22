---
layout: post
title: ARC, Swift closures and weak self
---
<img src="/images/fulls/swallowed_a_fly.jpg" class="fit image">

A commonly misunderstood/unknown feature of Swift closures is the *closure capture list*. It tells a closure how strongly to capture variables from the surrounding scope. This is useful in avoiding strong reference cycles. Strong reference cycles can prevent memory being freed when it's no longer needed - a memory leak.

Let's start at the beginning by explaining how strong reference cycles happen and why they're bad.

Automatic Reference Counting (ARC)
----------------------------------
iOS uses reference counting to determine when a reference type is no longer in use and it's memory can be freed.
It's a fairly simple concept: when a reference is in use it's retain count is increased.
When that use is finished the retain count is reduced.
When the retain count is 0 the reference can be safely removed.

<table>
<th>
<td>Action</td>
<td>Object A Created</td>
<td>A Passed to Object B</td>
<td>B deinit</td>
<td>A Creator deinit</td>
</th>
<tr>
<td>Retain Count</td>
<td>1</td>
<td>2</td>
<td>1</td>
<td>0</td>
<td>💥</td>
</tr>
</table>

Strong Reference Cycles
-----------------------
One drawback of ARC is that it's possible to create a reference cycle, where two objects reference each other - making it impossible for their retain counts to reach 0.

<table>
<th>
<td>Action</td>
<td>Object A created</td>
<td>Object A creates Object B</td>
<td>Object A is passed to Object B</td>
<td>Object A is release by it's parent</td>
</th>
<tr>
<td>Object A retain count</td>
<td>1</td>
<td>1</td>
<td>2</td>
<td>1</td>
</tr>
<tr>
<td>Object B retain count</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>1</td>
</tr>
</table>

At the end of this example both objects hold a reference to each other so they cannot be destroyed. Even though they are no longer in use.

Examples of strong reference cycles in documentation tend to be fairly contrived and it's pretty easy to avoid in practice.
However Swift closures have the ability to automatically capture their surrounding scope, making it more difficult to spot any reference cycles accidentally created this way.

Reference Cycles in Closures
----------------------------
There are two kinds of [closures](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html) we're concerned about - nested functions and closure expressions (yes nested functions are closure too!)

The two things to watch out for are:
1. closures that capture self. This can happen by using an instance property or instance method within a closure.
2. the possibility of that closure itself being assigned to self (either directly or by being assigned to a child of self)

A very common example of these two things occurs when using disposables in [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa).

`import ReactiveCocoa

class Thing {
  var disposable:Disposable
  var total:Int = 0

  deinit {
    disposable.dispose()
  }

  init(producer:SignalProducer<Int,NoError>) {
    disposable = producer.startWithNext{number in
      self.total += number
      print(self.total)
    }
  }
}`

In this example the closure captures self through the use of the `total` property. This adds to self's retain count.
This is ok so long as it is possible for the closure's own retain count can reach 0, releasing self and allowing it to be destroyed.
The problem occurs when a reference to the closure is kept by the disposable property.
This creates the cycle - the closure can't release self util self releases the closure.

Solutions
---------------------------
Closure expressions provide a *closure capture list* to change the strength of these references

`disposable = producer.startWithNext{[weak self] number in
  self?.total += number
  print(self?.total)
}`

Nested functions are slightly more verbose, requiring the weak/unowned variable to be created in the outer function, then captured by the nested function.

`func outer() {
  weak var this = self
  func inner() {
    this.number += 1
  }
}`

Remember you only need weak self if the nested function is assigned to a property on self, which doesn't happen in this snippet.

You can read more about ARC and weak and unowned references [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html).
More about closures [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html).
