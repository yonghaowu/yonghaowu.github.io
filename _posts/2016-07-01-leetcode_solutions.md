---
layout: post
title: leetcode解题笔记
description: 记录思路, 难点. 以及教是最好的学
categories:
- 技术
tags:
- C++
---

## 344. [Reverse String](https://leetcode.com/problems/reverse-string/)

> Write a function that takes a string as input and returns the string reversed.
> Example:
> Given s = "hello", return "olleh".

### Solution1(two pointers)

```
class Solution {
public:
    string reverseString(string s) {
        for(int i=0,j=s.length()-1; i<j; ++i,--j)
            swap(s[i], s[j]);
        return s;
    }
};
```

### Solution2(recursion)

```
class Solution {
public:
    string reverseString(string s) {
        const int len = s.length();
        if(len <= 1) return s;
        string left_str = s.substr(0, len/2);
        string right_str = s.substr(len/2, len-len/2);
        return reverseString(right_str) + reverseString(left_str) ;
    }
};
```

## 345. [Reverse Vowels of a String](https://leetcode.com/problems/reverse-vowels-of-a-string/)

> Write a function that takes a string as input and reverse only the vowels of a string.
> Example 1:
> Given s = "hello", return "holle".
> Example 2:
> Given s = "leetcode", return "leotcede".

The same as [Reverse String](https://leetcode.com/problems/reverse-string/), while we just need to switch the vowels. It is easy to come up with two pointers solution.
Besides, we can use find_first_of and find_last_of method of string. 

### Solution1(two pointers)

```
class Solution {
    public:
        string reverseVowels(string s) {
            string vowerls = "aeiouAEIOU";
            for(int i=0,j=s.length()-1; i<j; ) {
                if(vowerls.find(s[i]) == string::npos) {
                    ++i;
                }
                if(vowerls.find(s[j]) == string::npos) {
                    --j;
                }
                if(vowerls.find(s[i])!=string::npos && vowerls.find(s[j])!=string::npos) {
                    if(s[i] != s[j]) {
                        swap(s[i], s[j]);
                    }
                    ++i; --j;
                }
            }
            return s;
        }
};

class Solution {
public:
    string reverseVowels(string s) {
        auto p1 = s.begin(), p2 = s.end() - 1;
        string vowels = "aeiouAEIOU";
        while(p1 < p2) {
            while((vowels.find(*p1) == string::npos) && (p1 < p2)) p1++;
            while((vowels.find(*p2) == string::npos) && (p1 < p2)) p2--;
            if(p1 < p2) swap(*p1, *p2);
            p1++;
            p2--;
        }
        return s;
    }
};
```

### Solution2(find_first_of)

```
class Solution {
public:
    string reverseVowels(string s) {
        int i=0, j=s.length()-1;
        while(i < j) {
            i = s.find_first_of("aeiouAEIOU", i);
            j = s.find_last_of("aeiouAEIOU", j);
            /* pos	-	position at which to begin searching */

            /* need plus, as it just swap vowerls' place */
            if(i < j)
                swap(s[i++], s[j--]);
        }
        return s;
    }
};
```

## 371. [Sum of Two Integers](https://leetcode.com/problems/sum-of-two-integers/)

> Calculate the sum of two integers a and b, but you are not allowed to use the operator + and -.
> Example:
> Given a = 1 and b = 2, return 3.

If you have learn how machine do the add operation through bits or read the book Code, it is easy to know that using xor(^) operation can simulate add without carry. Then and(&) operation can simulate carry after shift(<<).
For example, 

```
101 + 101 = 1010 
101 ^ 101 = 000 //(without carry)
(101 & 101) << 1 =  1010 //carry
//After that, we add withoutarry add carry untill carry is 0

1010 ^ 000 = 1010
(1010 & 000) = 0000
```

### Solution1(using & and ^ to simulate add)

```
class Solution {
public:
    int getSum(int a, int b) {
        int sum = a;
        while(b) {
            sum = a^b;
            b = (a&b)<<1;
            a = sum;
        }
        return sum;
    }
};
```

## 257. [Binary Tree Paths](https://leetcode.com/problems/binary-tree-paths/)

> Given a binary tree, return all root-to-leaf paths.

We can use DFS(pre-order traverse) to get root-to-leaf paths.
If a leaf do not left child and right child, then we can think this is a root-to-leaf path, and we can push the string to vector.

### Solution(use DFS)
```
class Solution {
    public:
        vector<string> binaryTreePaths(TreeNode* root) {
            vector<string> vec;
            string res;
            travel(root, res, vec);
            return vec;
        }
    private:
        void travel(TreeNode* root, string res, vector<string> &vec) {
            if(root == nullptr)
                return;
            if((root->left==nullptr&&root->right==nullptr)) {
                res = res + to_string(root->val);
                vec.push_back(res);
                return;
            }
            res = res + to_string(root->val) + "->" ;
            travel(root->left, res, vec);
            travel(root->right,res, vec);
        }
};
```

### 234. [Palindrome Linked List](https://leetcode.com/problems/palindrome-linked-list/)

> Given a singly linked list, determine if it is a palindrome.

Reverse half of the linked list, then check whether they are equal.

# Solution(reverse)

```
class Solution {
public:
    bool isPalindrome(ListNode* head) {
        if(head == nullptr || head->next == nullptr)
            return true;
        ListNode *slow = head, *fast = head;
        while(fast->next && fast->next->next) {
            slow = slow->next;
            fast = fast->next->next;
        }
        slow->next = reverse_list(slow);
        slow = slow->next;
        while(slow) {
            if(head->val != slow->val)
                return false;

            slow = slow->next;
            head = head->next;
        }
        return true;
    }
private:
    ListNode *reverse_list(ListNode *slow) {
        ListNode *prev = slow;
        ListNode *cur, *tmp_next = prev->next;
        while(tmp_next) {
            cur = tmp_next;
            tmp_next = cur->next;
            cur->next = prev;
            prev = cur;
        }
        slow->next->next = nullptr;
        return cur;
    }
};
```

### 205. [Isomorphic Strings](https://leetcode.com/problems/isomorphic-strings/)

> Given two strings s and t, determine if they are isomorphic.
> Two strings are isomorphic if the characters in s can be replaced to get t.

For example, a <-> 7 instead of a->7, b->7, that means it needs two hash map to record the reflect.

```
class Solution {
public:
    bool isIsomorphic(string s, string t) {
        unordered_map<char, char> hash, reflect;
        for(int i=0; i<s.length(); ++i) {
            if(hash.find(s[i])==end(hash) && reflect.find(t[i])==end(reflect)) {
                hash[s[i]] = t[i];
                reflect[t[i]] = s[i];
            }else {
                if(hash[s[i]] != t[i])
                    return false;
            }
        }
        return true;
    }
};
```

### 204. [Count Primes](https://leetcode.com/problems/count-primes/)

> Count the number of prime numbers less than a non-negative number, n.

Table is often used in ACM to improve a program's performance.
It's a important skill to generate all the Composite numbers, e.g,

```
i=2 =>4,6,8,10,12
i=3 =>9,12,15,18,21
i=4 =>16,20,24,28,32,36

for(int j=i*i; j<n; j+=i)
    is_prime[j] = 0;
```

One tip is to use ```i*i``` instead of ```sqrt(n)```.

```
class Solution {
public:
    int countPrimes(int n) {
        int res = 0;
        vector<int> is_prime(n, 1);
        for(int i=2; i*i<n; ++i) {
            if(!is_prime[i])
                continue;
            res++;
            for(int j=i*i; j<n; j+=i) {
                is_prime[j] = 0;
            }
        }
        return res;
    }
};
```
