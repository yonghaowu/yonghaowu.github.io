---
layout: post
title: Hard Links, Junction Points 和 Symbolic Links的区别
---
Hard Links, Junction Points and Symbolic Links都是windows系统的链接机制，链接文件，目录或者盘。  
##Hard Link

通常，一个hard link代表另一个文件（源文件），相当于它的复制品，但又不会复制这个文件。NTFS格式的硬盘都存储所有文件的属性和内容到inode上，还存储了一个ID，文件名指向那个inode。而hard link就是让文件名指向那个inode来达到不重复文件内容却等价。所以所有文件至少有一个hard link（文件本身就算是hard link），文件的属性里还有一个计数器，来记录有多少hard link链接到它那里，假如为0，系统则删除这个文件，inode。 
Hard Link与源文件必须在同一个盘里。  

##Junction Point(又名directory hard link)

这也是hard link的一种，只不过代表的是文件夹，分区或者而已。  
与hard link最大区别就是可以跨越不同的盘。  

##Symbolic Link(又名soft link)

就是在windows里的快捷方式，可以跨越不同的盘。  

Reference:  
(1): http://comptb.cects.com/overview-to-understanding-hard-links-junction-points-and-symbolic-links-in-windows/  
(2): http://superuser.com/questions/67870/what-is-the-difference-between-ntfs-hard-links-and-directory-junctions  

=============

Hard Link (Linking for individual files):   
A file that acts like a representation of a target file on the same drive   
Has the same size as the target without duplicating it (doesn’t use any space)   
Interpreted at the operating system level (SW apps can act upon the target through the link)   
Deleting the Hard Link does not remove the target file   
If the target is deleted, its content is still available through the hard link   
Changing the contents through the Hard Link changes the target contents*   
Must reside on the same partition as the target file   
Compatible with Win2k and above in Windows   
* Some text editors save changed text to a new file and delete the original file, which can break the link. This behavior can be changed in some editors by forcing a save over the original file instead. See discussion at Jameser’s Tech Tips here for more information.   
Junction Point (Directory Hard Link):   
A file that acts like a representation of a target directory, partition or volume on the same system   
Has the same size as the target without duplicating it (doesn’t use any space)   
Interpreted at the operating system level – transparent to SW programs and users   
Deleting the Junction Point does not remove the target*   
If the target is moved, renamed or deleted, the Junction Point still exists, but points to a non-existing directory   
Changing the contents through the Junction Point changes the target contents   
Can reside on partitions or volumes separate from the target on the same system   
Compatible with Win2k and above in Windows   
*A Junction Point should never be removed in Win2k, Win2003 and WinXP with Explorer, the del or del /s commands, or with any utility that recursively walks directories since these will delete the target directory and all its subdirectories. Instead, use the rmdir command, the linkd utility, or fsutil (if using WinXP or above) or a third party tool to remove the junction point without affecting the target. In Vista/Win7, it’s safe to delete Junction Points with Explorer or with the rmdir and del commands.   
Symbolic Link (Soft Link):   
A file containing text interpreted by the operating system as a path to a file or directory   
Has a file size of zero   
Interpreted at the operating system level – transparent to SW programs and users   
Deleting the Symbolic Link does not remove the target   
If the target is moved, renamed or deleted, the link still exists, but points to a non-existing file or directory   
Points to, rather than represents, the target using relative paths   
Can reside on partitions or volumes separate from the target or on remote SMB network paths   
Compatible with UNIX and UNIX-like systems and with Vista and above in Windows   
Shortcut:   
A file interpreted by the Windows shell or other apps that understand them as paths to a file or directory   
File size corresponds to the binary information it contains   
Treated as ordinary files by the operating system and by SW programs that don’t understand them   
Deleting the shortcut does not remove the target   
Maintains references to target even if the target is moved or renamed, but is useless if the target is deleted   
Points to, rather than represents, the target   
Can reside on partitions or volumes separate from the target on the same System   
Compatible with all Windows versions  
  
  
  
