proc collection_to_list {a_collection} {
    set my_list {}
    foreach_in_collection item $a_collection {
        lappend my_list [get_object_name $item]
    }
    return $my_list
}
