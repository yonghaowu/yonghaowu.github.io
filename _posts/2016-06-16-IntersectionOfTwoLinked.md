---
layout: post
title: Intersection-of-Two-Linked-Lists
description: Write a program to find the node at which the intersection of two singly linked lists begins.
categories:
- 技术
tags:
- C++
---

#160. Intersection of Two Linked Lists
##Question
Write a program to find the node at which the intersection of two singly linked lists begins.

For example, the following two linked lists:

```
A:          a1 → a2
                   ↘
                     c1 → c2 → c3
                   ↗            
B:     b1 → b2 → b3
```

begin to intersect at node c1.


Notes:

* If the two linked lists have no intersection at all, return null.
* The linked lists must retain their original structure after the function returns.
* You may assume there are no cycles anywhere in the entire linked structure.
* Your code should preferably run in O(n) time and use only O(1) memory.

##Solution
###Approach #1 (count the difference of two list's length) [Accepted]
####Algorithm

At first, we calculate the length of list A and list B. 
If A is longer, curA traverse the steps' difference to arrive at the relative start position of curB and vice versa.
Then curA and curB traverse to the end together, eventually they will meet at the intersection point or nullptr.

```
class Solution {
    public:
        ListNode *getIntersectionNode(ListNode *headA, ListNode *headB) {
            int list_A_len = 0, list_B_len = 0, diff = 0;
            ListNode *tmp_A = headA;
            ListNode *tmp_B = headB;
            while(tmp_A) {
                tmp_A = tmp_A->next;
                ++list_A_len;
            }
            while(tmp_B) {
                tmp_B = tmp_B->next;
                ++list_B_len;
            }
            diff = list_A_len - list_B_len;
            if(diff > 0) {
                while(diff--) {
                    headA = headA->next;
                }
            }else {
                while(diff++) {
                    headB = headB->next;
                }
            }
            while(headA && headB) {
                if(headA == headB) {
                    return headA;
                }else {
                    headA = headA->next;
                    headB = headB->next;
                }
            }
            return nullptr;
        }
};
```
####Complexity Analysis

Suppose m is greater than n, the time complexity is ```O(m+n + m-n + n)```, in other words, ```O(2m+n)```.

* Time complexity : ```O(2m+n)```
* Space complexity : ```O(1)```

---

###Approach #2 (make a Linked List Cycle) [Accepted]
####Algorithm

Remember how to find the node where the [Linked List Cycle begins](https://leetcode.com/problems/linked-list-cycle-ii/)?

We can let listA tail's next equal to listB's head, so that listA and listB became a Linked List Cycle, whose Cycle begin node is IntersectionNode of list A and B.
After finding the IntersectionNode, we need to recover two lists from the Linked List Cycle by ```tail->next = nullptr;```

```
class Solution {
    public:
        ListNode *getIntersectionNode(ListNode *headA, ListNode *headB) {
            if(headA!=nullptr || headB!=nullptr)
                return nullptr;
            ListNode *pA = headA, *pB = headB;
            while(pA->next)
                pA = pA->next;
            ListNode *tail = pA;
            pA->next = pB;
            pA = headA;
            while(pB && pB->next) {
                 pB = pB->next->next;
                 pA = pA->next;
                 if(pB == pA)
                     break;
            }
            if(pA != pB)
                return nullptr;
            pA = headA;
            while(pA != pB) {
                 pA = pA->next;
                 pB = pB->next;
            }
            tail->next = nullptr;
            return pA;
        }
};
```

####Complexity Analysis

Suppose A's length is m while B is n, time complexity O(m+2m+k)

* Time complexity : ```O(3m+k)```
* Space complexity : ```O(1)```

###Approach #3 (loop back to the other list's head) [Accepted]
####Algorithm

I didn't come up with this idea, thanks for  [dong.wang.1694](https://leetcode.com/discuss/88940/simple-c-solution-5-lines).

Two pointers traverse to the end and any time they collide or reach end together without colliding then return any one of the pointers.
If one of them reaches the end earlier then reuse it by moving it to the beginning of other list.
Once both of them go through reassigning, they will be equidistant from the collision point.
Suppose list A's length is m, B's is n, while k is the length of the intersection part, A will traverse m+(n-k) and B will traverse n+(m-k), therefore, they are equal to n+m-k.

```
ListNode *getIntersectionNode(ListNode *headA, ListNode *headB) {
    ListNode *cur1 = headA, *cur2 = headB;
    while(cur1 != cur2){
        cur1 = cur1?cur1->next:headB;
        cur2 = cur2?cur2->next:headA;
    }
    return cur1;
}
```

* Time complexity : ```O(m+n-k)``` where k is the length of the intersection part
* Space complexity : ```O(1)```
