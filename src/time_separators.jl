module time_separators

function time2(x::Int64)
    if x <= 2002
        return 0 
    else 
        return 1
    end 
end 

function time3(x::Int64)
    if x <= 2000
        return 0 
    elseif x >= 2001 && x <= 2004
        return 1
    elseif x >= 2005 && x <= 2008
        return 2
    end 
end 

function time4(x::Int64)
    if x <= 1999
        return 0 
    elseif x >= 2000 && x <= 2002
        return 1
    elseif x >= 2003 && x <= 2005
        return 2
    elseif x >= 2006 && x <= 2008
        return 3
    end 
end 

function time5(x::Int64)
    if x <= 1999
        return 0 
    elseif x >= 2000 && x <= 2001
        return 1
    elseif x >= 2002 && x <= 2003
        return 2
    elseif x >= 2004 && x <= 2005
        return 3
    elseif x >= 2006 && x <= 2008
        return 4
    end 
end 



end #End of module 