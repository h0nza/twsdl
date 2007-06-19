set newDoc [::xml::document::create ::x testElement tst {xmlns:tst mystest:x}]

::xml::element::append $newDoc param1 "" {name length}

set child2 [::xml::element::append $newDoc param1 "" {name length2}]

set childchild [::xml::element::createRef ::y childchild "" {z eee p qqq}]

::xml::element::appendText $childchild "\nThis is some text in childchild\n"
::xml::element::appendText $childchild "Oh! one more thing"

# append childchild to child2
::xml::element::appendRef $child2 $childchild



ns_atclose "namespace delete ::x"
ns_atclose "namespace delete ::y"

ns_return 200 text/plain "[::xml::document::print $newDoc]"

