class ItemList {
  int data = 0;
  ItemList? next;

  ItemList(this.data);
}

// 原地指针反转链表，返回新的头结点
// 就是断链
// 1，2，3，4，5，null //curr=1，pre=null

//第一次：断开链表，变成2条链表
// 1,null   //pre=1
// 2,3,4,5,null //curr=2

//第二次：不断的将第二条链条的头节点挪到拆开的新链表的头节点位置
// 2，1，null //pre = 2
// 3，4，5，null //curr=3

//第三次：
// 3，2，1，null //pre=3
//4，5，null  //curer=4

//第四次：
//4，3，2，1，null //pre=4
//5，null //curr =5

//第五次
//5,4,3,2,1,null //pre=5
//null //curr=null

//第六次，
//null，退出while循环
ItemList? reverseListInPlace(ItemList? head) {
  ItemList? prev = null;
  ItemList? curr = head;

  while (curr != null) {
    ItemList? nextTemp = curr.next; // 先保存下一个节点
    curr.next = prev; // 当前节点指向前一个节点
    prev = curr; // prev向前移动
    curr = nextTemp; // curr向前移动
  }

  return prev; // prev是新链表头
}

void reverseList(ItemList head) {
  if (head.next == null) return;

  // 1. 找中点
  ItemList? slow = head;
  ItemList? fast = head;
  while (fast != null && fast.next != null) {
    slow = slow!.next;
    fast = fast.next!.next;
  }

  // 2. 入栈中点之前的节点
  List<ItemList> stack = [];
  ItemList? current = head;
  while (current != slow) {
    stack.add(current!);
    current = current.next;
  }

  // 3. 从中点开始往后，与栈中节点交换
  ItemList? right = slow;
  while (stack.isNotEmpty && right != null) {
    ItemList leftNode = stack.removeLast();
    int temp = leftNode.data;
    leftNode.data = right.data;
    right.data = temp;

    right = right.next;
  }
}

void main() {
  ItemList head = ItemList(1);
  head.next = ItemList(2);
  head.next!.next = ItemList(3);
  head.next!.next!.next = ItemList(4);
  head.next!.next!.next!.next = ItemList(5);

  print('反转前链表:');
  printList(head);

  ItemList? newHead = reverseListInPlace(head);

  print('反转后链表:');
  printList(newHead);
}

// 打印链表
void printList(ItemList? head) {
  ItemList? current = head;
  List<int> values = [];
  while (current != null) {
    values.add(current.data);
    current = current.next;
  }
  print(values.join(' -> '));
}
