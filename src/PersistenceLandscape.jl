#=     Copyright 2013-2014 University of Pennsylvania
#     Created by Pawel Dlotko
#
#     This file is part of Persistence Landscape Toolbox (PLT).
#
#     PLT is free software: you can redistribute it and/or modify
#     it under the terms of the GNU Lesser General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     PLT is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU Lesser General Public License for more details.
#
#     You should have received a copy of the GNU Lesser General Public License
#     along with PLT.  If not, see <http:# www.gnu.org/licenses/>.
=#

#include "Configure.h"

import Base.+, Base.-, Base.*, Base.+=

include("Configure.jl")
include("PersistenceBarcode.jl")

struct PersistenceLandscape
    land::Vector{MyPair[]}
    dimension::UInt
end

function almostEqual( a::Float64 , b::Float64 )
    if abs(a-b) < eps
        return true
    end
    return false
end

function birth (a::MyPair)
    return a.first-a.second
end

function death(a::MyPair )
    return a.first+a.second
end

# functions used in PersistenceLandscape( PersistenceBarcodes& p ) constructor:
# comparePointsDBG::Bool = false
function comparePoints( f::MyPair, s::MyPair )
    differenceBirth = birth(f)-birth(s)

    if differenceBirth < 0
        differenceBirth *= -1
    end

    differenceDeath = death(f)-death(s)
    if differenceDeath < 0
        differenceDeath *= -1
    end

    if (differenceBirth < epsi) && (differenceDeath < epsi)
        if comparePointsDBG
            println("CP1")
        end
        return false
    end
    if differenceBirth < epsi
        # consider birth points the same. If we are here, we know that death points are NOT the same
        if death(f) < death(s)
            if comparePointsDBG
                println("CP2")
            end
            return true
        end
        if(comparePointsDBG)
            println("CP3")
        end
        return false
    end
    if differenceDeath < epsi
        # we consider death points the same and since we are here, the birth points are not the same!
        if birth(f) < birth(s)
            if(comparePointsDBG)
				println("CP4")
            end
            return false
        end
        if(comparePointsDBG)
            println("CP5")
        end
        return true
    end
    if birth(f) > birth(s)
        if(comparePointsDBG)
            println("CP6")
        end
        return false
    end
    if birth(f) < birth(s)
        if(comparePointsDBG)
            println("CP7")
        end
        return true
    end
    # if this is true, we assume that death(f)<=death(s) -- othervise I have had a lot of roundoff problems here!
    if death(f)<=death(s)
        if(comparePointsDBG)
            println("CP8")
        end
        return false
    end
    if(comparePointsDBG)
        println("CP9")
    end
    return true
end

# this function assumes birth-death coords
function comparePoints2(f::MyPair, s::MyPair )
    if f.first < s.first
        return true
    else
        if f.first > s.first
            return false
        else
        # f.first == s.first
            if f.second > s.second
                return true
            else
                return false
            end
        end
    end
end

# class vectorSpaceOfPersistenceLandscapes
# functions used to add and subtract landscapes

function add(x::Float64, y::Float64)
    return x+y
end

function sub(x::Float64, y::Float64)
    return x-y
end

# function used in computeValueAtAGivenPoint
function functionValue( p1::MyPair, p2::MyPair , x::Float64 )
    # we assume here, that x \in [ p1.first, p2.first ] and p1 and p2 are points between which we will put the line segment
    a = (p2.second - p1.second)/(p2.first - p1.first)
    b = p1.second - a*p1.first
    # println("Line crossing points : ($(p1.first << ",$(p1.second)) oraz (" << p2.first) $(p2.second)) :")")
    # println("a : $(a) $(b) , x : $(x)")
    return (a*x+b)
end

# class PersistenceLandscape

function lDimBegin(land::PersistenceLandscape, dim::UInt)
    if dim > size(land,1)
        throw(DomainError("Calling lDimIterator in a dimension higher that dimension of landscape"))
    end
    return land[dim][1]
end

function lDimEnd(unsigned dim)
    if dim > size(land,1)
        throw(DomainError("Calling lDimIterator in a dimension higher that dimension of landscape"))
    end
    return land[dim][end]
end

# functionzone:
# this is a general algorithm to perform linear operations on persisntece lapscapes. It perform it by doing operations on landscape points.

# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-
# Basic operations on PersistenceLandscape >>>
function operationOnPairOfLandscapes(land1, land2 , oper);

function addTwoLandscapes( land1::PersistenceLandscape, land2::PersistenceLandscape)::PersistenceLandscape
    return operationOnPairOfLandscapes(land1,land2, +)
end

function subtractTwoLandscapes( land1::PersistenceLandscape, land2::PersistenceLandscape)::PersistenceLandscape
    return operationOnPairOfLandscapes(land1,land2, -)
end

function Base.+( first::PersistenceLandscape,second::PersistenceLandscape)
    return addTwoLandscapes(first, second)
end

function Base.-( first::PersistenceLandscape,second::PersistenceLandscape)
    return subtractTwoLandscapes(first, second )
end

function Base.*( first::PersistenceLandscape, con::Float64 )
    return multiplyLanscapeByRealNumberNotOverwrite(first, con)
end

function Base.*( con::Float64, first::PersistenceLandscape)
    return multiplyLanscapeByRealNumberNotOverwrite(first, con)
end

# function Base.+=(this::PersistenceLandscape, rhs::PersistenceLandscape)
#     return this + rhs
# end
#
# function Base.-=(this::PersistenceLandscape, rhs::PersistenceLandscape)
#     return this - rhs
# end
#
# function Base.*=(this::PersistenceLandscape, x::Float64 )
#     return this * x
# end

function Base./(this::PersistenceLandscape, x::Float64 )
    x == 0  && throw(DomainError("In Base./=, division by 0. Program terminated." ))
    return this / x
end

# function Base./=(this::PersistenceLandscape, x::Float64 )
#     x == 0  && throw(DomainError("In Base./=, division by 0. Program terminated." ))
#     return this / x
# end

# function Base.==(this::PersistenceLandscape,rhs ::PersistenceLandscape)::Bool
#     return this == rhs
# end

function Base.== (lhs::PersistenceLandscape, rhs ::PersistenceLandscape; operatorEqualDbg=false)
    if size(lhs.land,1) != size(rhs.land,1)
        operatorEqualDbg && println("1")
        return false
    end

    # check if every elements are the same
    @error "This function is not fully translated!!!"
    for level = 1 : size(lhs.land,1)
        if size(lhs.land[level]) != size(rhs.land[level])
            if (operatorEqualDbg)
                println("size(lhs.land[level]) : $(size(lhs.land[level]))")
                println("size(rhs.land[level]) : $(size(rhs.land[level]))")
                println("2")
            end
            return false
        end
        for i = 1 : size(land[level])
            if lhs.land[level][i] != rhs.land[level][i]
                if (operatorEqualDbg)
                    println("lhs.land[level][i] : $(lhs.land[level][i])")
                    println("rhs.land[level][i] : $(rhs.land[level][i])")
                    println("3")
                end
                return false
            end
        end
    end
    return true
end

# function operator=(land::PersistenceLandscape, oryginal::PersistenceLandscape)
    # remved, vbecause unnecesssary 
# end

function Base.size(land::PersistenceLandscape)
    return size(land.land,1)
end
# ===-===-===-

# Should be ready for testing
function operationOnPairOfLandscapes ( land1::PersistenceLandscape, land2::PersistenceLandscape, oper; local_dbg = false)
    local_dbg && println("operationOnPairOfLandscapes")

    # PersistenceLandscape result
    result = Dict(:land => Any[], :dims => 0)

    land = Any[]
    # result.land = land

    for i = 1 : min( size(land1.land) , size(land2.land) )
        lambda_n = MyPair[]
        p = 1
        q = 1

        while ( (p+1 < size(land1.land[i])) && (q+1 < size(land2.land[i])) )
            # if local_dbg
            #     println("p : $(p)")
            #     println("q : $(q)")
            #     println("land1.land[i][p].first : $(land1.land[i][p].first)")
            #     println("land2.land[i][q].first : $(land2.land[i][q].first)")
            # end
            if land1.land[i][p].first < land2.land[i][q].first
                # if local_dbg
                #     println("first")
                #     println(" functionValue(land2.land[i][q-1],land2.land[i][q],land1.land[i][p].first) : "<<  functionValue(land2.land[i][q-1],land2.land[i][q],land1.land[i][p].first) << "")
                #     println("oper( $(land1.land[i][p].second),$(functionValue(land2.land[i][q-1],land2.land[i][q],land1.land[i][p].first)) $(oper( land1.land[i][p].second , functionValue(land2.land[i][q-1],land2.land[i][q],land1.land[i][p].first) ))")
                # end
                end_value = functionValue(land2.land[i][q-1],
                                            land2.land[i][q],
                                            land1.land[i][p].first
                                           )
                operaion_result = oper(land1.land[i][p].second, end_value)
                new_pair = make_pair(land1.land[i][p].first , operaion_result)

                push!(lambda_n, new_pair)

                p += 1
                continue
            end
            if land1.land[i][p].first > land2.land[i][q].first
                # if local_dbg
                #     println("Second")
                #     println("functionValue("<< land1.land[i][p-1]<<" ,"<< land1.land[i][p]<<", $(land2.land[i][q].first<<" ) : " << functionValue( land1.land[i][p-1] , land1.land[i][p-1] ,land2.land[i][q].first ))")
                #     println("oper( $(functionValue( land1.land[i][p] , land1.land[i][p-1] ,land2.land[i][q].first ) <<",$(land2.land[i][q].second) : " << oper( land2.land[i][q].second , functionValue( land1.land[i][p] , land1.land[i][p-1] ,land2.land[i][q].first ) )))")
                # end
                end_value = functionValue(land1.land[i][p],
                                            land1.land[i][p-1],
                                            land2.land[i][q].first
                                            )
                operation_result = oper(end_value, land2.land[i][q].second)
                new_pair = make_pair(land2.land[i][q].first, operatioin_result)
                push!(lambda_n, new_pair)
                q += 1
                continue
            end
            if land1.land[i][p].first == land2.land[i][q].first
                # local_dbg && println("Third")
                operation_result = oper(land1.land[i][p].second ,land2.land[i][q].second)

                new_pair = make_pair(land2.land[i][q].first, operation_result)

                push!(lambda_n, new_pair)
                p += 1
                q += 1
            end
            local_dbg && println("Next iteration")
                # getchar())
        end

        while (p+1 < size(land1.land[i], 1)) && (q+1 >= size(land2.land[i], 1))
            local_dbg && println("New point : $(land1.land[i][p].first)  oper(land1.land[i][p].second,0) : $( oper(land1.land[i][p].second,0))")

            oper_result = oper(land1.land[i][p].second, 0)
            new_pair = make_pair(land1.land[i][p].first , oper_result)

            push!(lambda_n, new_pair)
            p += 1
        end

        while (p+1 >= size(land1.land[i])) && (q+1 < size(land2.land[i]))

            local_dbg && println("New point : $(land2.land[i][q].first) oper(0,land2.land[i][q].second) : $( oper(0,land2.land[i][q].second))")

            oper_result = oper(0,land2.land[i][q].second)
            new_pair = make_pair(land2.land[i][q].first, oper_result)

            push!(lambda_n, new_pair)
            q += 1
        end

        push!(lambda_n,  make_pair( Inf, 0 ) )
        # CHANGE
        # result.land[i] = lambda_n
        push!(result[:land], lambda_n)
    end

    # Modify results
    if size(land1.land,1) > min( size(land1.land,1) , size(land2.land,1) )
        local_dbg && println("size(land1.land,1) > std::min( size(land1.land,1) , size(land2.land,1) )$()")

        start_val = min(size(land1.land,1), size(land2.land,1) )
        stop_val = max(size(land1.land,1), size(land2.land,1) )
        for i = start_val:stop_val

            lambda_n = MyPair[]
            for nr = 1 : size(land1.land[i])
                oper_result = oper(land1.land[i][nr].second, 0)

                new_pair = make_pair(land1.land[i][nr].first, oper_result)
                push!(lambda_n, new_pair)
            end

            # CHANGE
            # result.land[i] = lambda_n
            result[:land][i] = lambda_n
        end
    end

    if size(land2.land,1) > min( size(land1.land,1) , size(land2.land,1) )
        local_dbg && println("( size(land2.land,1) > std::min( size(land1.land,1) , size(land2.land,1) ) ) $()")

        start_val = min( size(land1.land,1) , size(land2.land,1) )
        stop_val = max( size(land1.land,1) , size(land2.land,1) )
        for i = start_val:stop_val
            lambda_n = MyPair[]

            for nr = 0 : size(land2.land[i])
                oper_result = oper(0 , land2.land[i][nr].second)

                new_pair = make_pair( land2.land[i][nr].first, oper_result)
                push!(lambda_n, new_pair)
            end
            # CHANGE
            # result.land[i] = lambda_n
            result[:land][i] = lambda_n
        end
    end

    local_dbg && println("operationOnPairOfLandscapes")

    # return result
    return PersistenceLandscape(result[:land], result[:dims])
end# operationOnPairOfLandscapes



# Basic operations on PersistenceLandscape <<<
# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-

function computeMaximum(land::PersistenceLandscape)
    maxValue = 0
    if size(land,1) != 0
        maxValue = -Inf
        for i = 1:size(land[0], 1)
            if land[1][i].second > maxValue
                maxValue = land[1][i].second
            end
        end
    end
    return maxValue
end

function computeNormOfLandscape(land::PersistenceLandscape, i::Int )
    l = PersistenceLandscape()
    if i != -1
        return computeDiscanceOfLandscapes(land,l,i)
    else
        return computeMaxNormDiscanceOfLandscapes(land,l)
    end
end

# Empty constructor?
# function operator()(level:UInt, x::Float64)
#     return computeValueAtAGivenPoint(level,x)
# end

function dim(land::PersistenceLandscape)
    # @info "Not sure if this should work this way"
    return land.dimension
end

function minimalNonzeroPoint(land::PersistenceLandscape, l::UInt )
    if size(land,1) < l
        return Inf
    end
    return land[l][1].first
end

function maximalNonzeroPoint(land::PersistenceLandscape, l::UInt )
    if size(land,1) < l
        return -Inf
    end
    return land[l][size(land[l],1)-2].first
end


# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-
# visualization part...
# To be created in Julia


# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-
# Constructors >>>
function PersistenceLandscape(land::::PersistenceLandscape, landscapePointsWithoutInfinities::Vector{Vector{MyPair}})
    for level = 0:size(landscapePointsWithoutInfinities)
        v = MyPair[]
        push!(v, make_pair(INT_MIN,0))
        v.insert( v.end(), landscapePointsWithoutInfinities[level].begin(), landscapePointsWithoutInfinities[level].end() )
        push!(v, make_pair(INT_MAX,0))
        push!(land, v )
    end
    land.dimension = 0
end

# Constructor form file
function PersistenceLandscape(land::PersistenceLandscape, filename::String;    bool dbg = false)
    land_vecto = copy(land.land)
    if dbg
        println("Using constructor : PersistenceLandscape $(filename)")
    end
    if !check_if_file_exist( filename )
        println("The file : $(filename) do not exist. The program will now terminate")
        throw(SystemError("File not exist, please consult output of the program for further details."))
	end
    # this constructor reads persistence landscape form a file. This file have to be created by this software beforehead

    dimension = 0
    open(filename, "r") do io
        # read till end of file
        s = readline(f)
        dimension = UInt(s)

        isThisAFirsLine = true
        line = ""
        landscapeAtThisLevel = MyPair[]

        while !eof(io)
            s = readline(io)
            if !(line.length() == 0 || line[0] == '#')
                lineSS = line
                splitted = split(lineSS , " ")
                beginning = splitted[1]
                ending= splitted[2]


                push!(landscapeAtThisLevel,  make_pair( beginning , ending ))
                if (dbg)
                    println("Reading a pont : $(beginning), $(ending)")
                else
                    if (dbg)
                        println("IGNORE LINE")
                        # getchar()
                    end
                    if !isThisAFirsLine
                        push!(landscapeAtThisLevel, make_pair(Inf, 0))
                        push!(land_vecto, landscapeAtThisLevel)
                        landscapeAtThisLevel = MyPair[]
                    end
                    push!(landscapeAtThisLevel, make_pair(-Inf, 0))
                    isThisAFirsLine = false
                end
            end
        end
    end
    if size(landscapeAtThisLevel,1) > 1
        # seems that the last line of the file is not finished with the newline sign. We need to put what we have in landscapeAtThisLevel to the constructed landscape.
        push!(landscapeAtThisLevel, make_pair(Inf, 0))
        push!(land_vecto,landscapeAtThisLevel)
    end
    return PersistenceLandscape(land_vecto, dimension)
end

# copy constructor- not necessary for Julia
# function PersistenceLandscape(land::PersistenceLandscape, oryginal::PersistenceLandscape)
    # println("Running copy constructor")
    # land = Any[]
    # for i = 1 : size(oryginal.land)
    #     push!(land, (land[i].end(), oryginal.land[i].begin(), oryginal.land[i].end())
    #      )
    # end
    # # CHANGE
    # # land.land = land
    # return PersistenceLandscape(land, oryginal.dimension)
# end

# if check( , )
# println("OUT OF MEMORY")

# Constructor
function PersistenceLandscape(land::PersistenceLandscape,  p::PersistenceBarcodes; dbg = false)
    dbg && println("PersistenceLandscape(land::::PersistenceLandscape,  PersistenceBarcodes& p )" )

    if !useGridInComputations
        dbg && println("PL version")
        # this is a general algorithm to construct persistence landscapes.
        land.dimension = p.dimensionOfBarcode
        bars = MyPair[]

        bars.insert( bars.begin() , p.barcodes.begin() , p.barcodes.end() )
        sort( bars.begin() , bars.end() , comparePoints2 )

        if (dbg)
            println("Bars :")
            for i = 0 : bars.size()
                println("$(bars[i])")
            end
            # getchar()
        end

        characteristicPoints = MyPair[]
        for i = 1 : bars.size()
            push!(characteristicPoints, make_pair((bars[i].first+bars[i].second)/2.0 , (bars[i].second - bars[i].first)/2.0))
        end

        persistenceLandscape = MyPair[]
        while ( !characteristicPoints.empty() )
            if(dbg)
                for i = 1 : characteristicPoints.size()
                    println("($(characteristicPoints[i]))")
                end
                cin.ignore()
            end
            lambda_n = MyPair[]
            push!(lambda_n,  make_pair( INT_MIN , 0 ) )
            push!(lambda_n,  make_pair(birth(characteristicPoints[0]),0) )
            push!(lambda_n,  characteristicPoints[0] )

            dbg && println("1 Adding to lambda_n : ($(make_pair( INT_MIN , 0 ))) , ($(std::make_pair(birth(characteristicPoints[0]),0)) $(characteristicPoints[0])))")

            i = 1
            newCharacteristicPoints = MyPair[]
            while ( i < characteristicPoints.size() )
                 p = 1
                 if (birth(characteristicPoints[i]) >= birth(lambda_n[lambda_n.size()-1]))
                    &&
                    (death(characteristicPoints[i]) > death(lambda_n[lambda_n.size()-1]))

                    if birth(characteristicPoints[i]) < death(lambda_n[lambda_n.size()-1])
                        po::MyPairint = make_pair( (birth(characteristicPoints[i])+death(lambda_n[lambda_n.size()-1]))/2 , (death(lambda_n[lambda_n.size()-1])-birth(characteristicPoints[i]))/2 )
                        push!(lambda_n,  point )

                        # dbg && println("2 Adding to lambda_n : ($(point))")
                        # if dbg
                        #     println("comparePoints(point,characteristicPoints[i+p]) : $(comparePoints(point,characteristicPoints[i+p]))")
                        #     println("characteristicPoints[i+p] : $(characteristicPoints[i+p])")
                        #     println("point : $(point)")
                        #     # getchar()
                        # end

                        while (
                               (i+p < characteristicPoints.size() )
                               &&
                               (almostEqual(birth(point),birth(characteristicPoints[i+p])))
                               &&
                               (death(point) <= death(characteristicPoints[i+p]))
                              )
                            push!(newCharacteristicPoints,  characteristicPoints[i+p] )
                            # dbg && println("3.5 Adding to newCharacteristicPoints : ($(characteristicPoints[i+p]))")
                                # getchar()
                            p += 1
                        end
                        push!(newCharacteristicPoints,  point )

                        # dbg && println("4 Adding to newCharacteristicPoints : ($(point))")
                        while (
                               (i+p < characteristicPoints.size() )
                               &&
                               ( birth(point) <= birth(characteristicPoints[i+p]) )
                               &&
                               (death(point)>=death(characteristicPoints[i+p])) 
                              )
                            push!(newCharacteristicPoints,  characteristicPoints[i+p] )
                            # if (dbg)
                            #     println("characteristicPoints[i+p] : $(characteristicPoints[i+p])")
                            #     println("point : $(point)")
                            #     println("comparePoints(point,characteristicPoints[i+p]) : $(comparePoints(point,characteristicPoints[i+p]))")
                            #     println("characteristicPoints[i+p] birth and death : $(birth(characteristicPoints[i+p])) $(death(characteristicPoints[i+p]))")
                            #     println("point birth and death : $(birth(point)) $(death(point))")
                            #     println("3 Adding to newCharacteristicPoints : ($(characteristicPoints[i+p]))")
                            #     # getchar()
                            # end
                            p += 1
                        end
                    else
                        push!(lambda_n,  make_pair( death(lambda_n[lambda_n.size()-1]) , 0 ) )
                        push!(lambda_n,  make_pair( birth(characteristicPoints[i]) , 0 ) )
                        # if (dbg)
                        #     println("5 Adding to lambda_n : ($(make_pair( death(lambda_n[lambda_n.size()-1]) , 0 )))")
                        #     println("5 Adding to lambda_n : ($(make_pair( birth(characteristicPoints[i]) , 0 )))")
                        # end
                    end
                    push!(lambda_n,  characteristicPoints[i] )
                    # dbg && println("6 Adding to lambda_n : ($(characteristicPoints[i]))")
                else
                    push!(newCharacteristicPoints,  characteristicPoints[i] )
                    # dbg && println("7 Adding to newCharacteristicPoints : ($(characteristicPoints[i]))")
                end
                i = i+p
            end
            push!(lambda_n,  make_pair(death(lambda_n[lambda_n.size()-1]),0) )
            push!(lambda_n,  make_pair( INT_MAX , 0 ) )
            # CHANGE
            characteristicPoints = newCharacteristicPoints
            # characteristicPoints.swap(newCharacteristicPoints)
            lambda_n.erase(unique(lambda_n.begin(), lambda_n.end()), lambda_n.end())
            push!(land, lambda_n )
    else
        # dbg && println("Constructing persistence landscape based on a grid");# getchar())

        # in this case useGridInComputations is true, therefore we will build a landscape on a grid.
        externgridDiameter
        land.dimension = p.dimensionOfBarcode
        pair minMax = p.minMax()
         numberOfBins = 2*((minMax.second - minMax.first)/gridDiameter)+1

        # first element of a pa::MyPairir<, vector<double> > is a x-value. Second element is a vector of values of landscapes.

        # vector< pair<, std::vector<double> > > criticalValuesOnPointsOfGrid(numberOfBins)
        criticalValuesOnPointsOfGrid = Any[]

        # filling up the bins:
        # Now, the idea is to iterate on land.land[lambda-1] and use only points over there. The problem is at the very beginning, when there is nothing
        # in land.land. That is why over here, we make a fate this->land[0]. It will be later deteted before moving on.

        aa = MyPair[]
        push!(aa,  make_pair( INT_MIN , 0 ) )

        x = minMax.first
        for i = 0 : numberOfBins
            v = Float64[]
            # pair<, vector<double> > p = std::make_pair( x , v )
            p = (x , v )
            push!(aa,  make_pair( x , 0 ) )
            push!(criticalValuesOnPointsOfGrid[i], p)
            # dbg && println("x : $(x)")
            x += 0.5*gridDiameter
        end

        push!(aa,  make_pair( INT_MAX , 0 ) )
        # dbg && println("Grid has been created. Now, begin to add intervals")
        # for every peristent interval
        for ervalNo = 0 : p.size()
            beginn = ()(2*( p.barcodes[intervalNo].first-minMax.first )/( gridDiameter ))+1
            # dbg && println("We are considering interval : [$(p.barcodes[intervalNo].first),$(p.barcodes[intervalNo].second) $(beginn) in the grid")
            while ( criticalValuesOnPointsOfGrid[beginn].first < p.barcodes[intervalNo].second )
                # dbg && println("Adding a value : ($(criticalValuesOnPointsOfGrid[beginn].first) $(min( abs(criticalValuesOnPointsOfGrid[beginn].first-p.barcodes[intervalNo].first) ,abs(criticalValuesOnPointsOfGrid[beginn].first-p.barcodes[intervalNo].second) ))) ")
                criticalValuesOnPointsOfGrid[beginn].second.push_back(min( abs(criticalValuesOnPointsOfGrid[beginn].first-p.barcodes[intervalNo].first) ,abs(criticalValuesOnPointsOfGrid[beginn].first-p.barcodes[intervalNo].second) ) )
                beginn += 1
            end
        end
        # now, the basic structure is created. We need to translate it to a persistence landscape data structure.
        # To do so, first we need to sort all the vectors in criticalValuesOnPointsOfGrid[i].second
         maxNonzeroLambda = 0
        for i = 0 : criticalValuesOnPointsOfGrid.size() 
            sort( criticalValuesOnPointsOfGrid[i].second.begin() , criticalValuesOnPointsOfGrid[i].second.end() , greater<int>() )
            if criticalValuesOnPointsOfGrid[i].second.size() > maxNonzeroLambda
                maxNonzeroLambda = criticalValuesOnPointsOfGrid[i].second.size()
            end
        end
        # if dbg
        #     println("After sorting")
        #     for i = 0 : criticalValuesOnPointsOfGrid.size() 
        #         println("x : $(criticalValuesOnPointsOfGrid[i].first << " : ")")
        #         for j = 0 : criticalValuesOnPointsOfGrid[i].second.size() 
        #             println(criticalValuesOnPointsOfGrid[i].second[j] << " ")
        #         end
        #         println("\n")
        #     end
        # end
        push!(land,aa)
        for lambda = 0 : maxNonzeroLambda 
            # dbg && println("Constructing lambda_$(lambda)")
            nextLambbda = MyPair[]

            push!(nextLambbda,  make_pair(INT_MIN,0) )

            # for every element in the domain for which the previous landscape is nonzero.
            wasPrevoiusStepZero = true
            nr = 1
            while nr < size(land.land[ size(land,1)-1 ])-1
                # dbg  && println("nr : $(nr)")
                 address = ()(2*( land.land[ size(land,1)-1 ][nr].first-minMax.first )/( gridDiameter ))
                # dbg && println("We are considering the element x : $(land.land[ size(land,1)-1 ][nr].first). Its position in the structure is : $(address)")
                if  criticalValuesOnPointsOfGrid[address].second.size() <= lambda
                    if (!wasPrevoiusStepZero)
                        wasPrevoiusStepZero = true
                        # dbg && println("AAAdding : ($(criticalValuesOnPointsOfGrid[address].first) $(0)) to lambda_$(lambda;# getchar())")
                        push!(nextLambbda,  make_pair( criticalValuesOnPointsOfGrid[address].first , 0 ) )
                    end
                else
                     if wasPrevoiusStepZero
                         # dbg && println("Adding : ($(criticalValuesOnPointsOfGrid[address-1].first) $(0)) to lambda_$(lambda;# getchar())")
                         push!(nextLambbda,  make_pair( criticalValuesOnPointsOfGrid[address-1].first , 0 ) )
                         wasPrevoiusStepZero = false
                     end
                     # dbg && println("AAdding : ($(criticalValuesOnPointsOfGrid[address].first) $(criticalValuesOnPointsOfGrid[address].second[lambda])) to lambda_$(lambda;# getchar())")
                     push!(nextLambbda,  make_pair( criticalValuesOnPointsOfGrid[address].first , criticalValuesOnPointsOfGrid[address].second[lambda] ) )
                end
                nr += 1
            end

            # dbg && println("Done with : lambda_$(lambda;# getchar();getchar();getchar())")

            if lambda == 0
                # removing the first, fake, landscape
                land.land.clear()
            end
            push!(nextLambbda,  make_pair(INT_MAX,0) )
            nextLambbda.erase( unique( nextLambbda.begin(), nextLambbda.end() ), nextLambbda.end() )
            push!(land, nextLambbda )
        end
    end
end
# Constructors <<<
# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-



# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-
# CAUTION, this procedure do not work yet. Please do not use it until this warning is removed.
# PersistenceBarcodes PersistenceLandscape::convertToBarcode()
# function body removed
# 
# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-




# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-
# Operations on landscapes 
# this function find maximum of lambda_n
function gimmeProperLandscapePoints(land::PersistenceLandscape)::Vector{MyPair}
    result = MyPair[]
    for level = 1:size(land,1)
        v = MyPair( land[level].begin()+1 , land[level].end()-1 )
        push!(result, v)
    end
    return result
end

function check_if_file_exist(name::String)
    return isfile(name)
end

function findMax(land::PersistenceLandscape, unsigned lambda )const
    if ( size(land,1) < lambda )return 0
   maximum = INT_MIN
    for i = 0 : land.land[lambda].size()
        if land.land[lambda][i].second > maximum
            maximum = land.land[lambda][i].second
        end
    end
    return maximum
end

# this function compute n-th moment of lambda_level
function computeNthMoment(land::PersistenceLandscape, unsigned n , center , unsigned level; computeNthMomentDbg = false)
    if n < 1
        println("Cannot compute n-th moment for  n = $(n << ". The program will now terminate")")
        throw("Cannot compute n-th moment. The program will now terminate")
    end
   result = 0
    if size(land,1) > level
        for i = 2 : land.land[level].size()-1 
            if land.land[level][i].first - this->land[level][i-1].first == 0
                continue
            end
            # between land.land[level][i] and this->land[level][i-1] the lambda_level is of the form ax+b. First we need to find a and b.
            a = (land.land[level][i].second - this->land[level][i-1].second)/(this->land[level][i].first - this->land[level][i-1].first)
            b = land.land[level][i-1].second - a*this->land[level][i-1].first
            x1 = land.land[level][i-1].first
            x2 = land.land[level][i].first
            #first = b*(pow((x2-center),(double)(n+1))/(n+1)-pow((x1-center),(double)(n+1))/(n+1))
            #second = a/(n+1)*((x2*pow((x2-center),(double)(n+1))) - (x1*pow((x1-center),(double)(n+1))) )
            #               +
            #               a/(n+1)*( pow((x2-center),(double)(n+2))/(n+2) - pow((x1-center),(double)(n+2))/(n+2) )
            # result += first
            # result += second
            first = a/(n+2)*( pow( (x2-center) , (double)(n+2) ) - pow( (x1-center) , (double)(n+2) ) )
            second = center/(n+1)*( pow( (x2-center) , (double)(n+1) ) - pow( (x1-center) , (double)(n+1) ) )
            third = b/(n+1)*( pow( (x2-center) , (double)(n+1) ) - pow( (x1-center) , (double)(n+1) ) )
            if computeNthMomentDbg
                println("x1 : $(x1)")
                println("x2 : $(x2)")
                println("a : $(a)")
                println("b : $(b)")
                println("first : $(first)")
                println("second : $(second)")
                println("third : $(third)")
                # getchar()
            end
            result += first + second + third
        end
    end
    return result
end# computeNthMoment

function testLandscape(land::PersistenceLandscape, PersistenceBarcodes& b )
    for level = 1 : size(land,1) 
        for i = 1 : land.land[level].size()-1 
            if land.land[level][i].second < epsi
                continue
            end
            # check if over land.land[level][i].first-this->land[level][i].second , this->land[level][i].first+this->land[level][i].second] there are level barcodes.
            nrOfOverlapping = 0
            for nr = 1 : b.barcodes.size() 
                if ( b.barcodes[nr].first-epsi <= land.land[level][i].first-this->land[level][i].second
                      &&
                      ( b.barcodes[nr].second+epsi >= land.land[level][i].first+this->land[level][i].second )
                   )
                    nrOfOverlapping += 1
                end
            end
            if nrOfOverlapping != level+1
                println("We have a problem :")
                println("land.land[level][i].first : $(this->land[level][i].first)")
                println("land.land[level][i].second : $(this->land[level][i].second)")
                println("[$(land.land[level][i].first-this->land[level][i].second) $(this->land[level][i].first+this->land[level][i].second)]")
                println("level : $(level) , nrOfOverlapping: $(nrOfOverlapping)")
                # getchar()
                for nr = 1 : b.barcodes.size() 
                    if ( b.barcodes[nr].first <= land.land[level][i].first-this->land[level][i].second
                          &&
                          ( b.barcodes[nr].second >= land.land[level][i].first+this->land[level][i].second )
                       )
                        println("($(b.barcodes[nr].first) $(b.barcodes[nr].second))")
                    end
                    # land.printToFiles("out")
                    # land.generateGnuplotCommandToPlot("out")
                    # # getchar();getchar();getchar()
                end
            end
        end
    end
    return true
end


function computeLandscapeOnDiscreteSetOfPoints(land::PersistenceLandscape, PersistenceBarcodes& b ,dx; local_dbg = false)
     pair miMa = b.minMax()
    bmin = miMa.first
    bmax = miMa.second
     if(local_dbg)
				println("bmin: $(bmin) $(bmax)")
    # if(local_dbg)end
     vector< pair<double,std::vector<double> > > result( (bmax-bmin)/(dx/2) + 2 )
     x = bmin
     int i = 0
     while ( x <= bmax )
         vector<double> v
         result[i] = make_pair( x , v )
         x += dx/2.0
         i += 1
     end
     if(local_dbg)
				println("Vector initally filled in")
     for i = 0 : b.barcodes.size() 
         # adding barcode b.barcodes[i] to out mesh:
        beginBar = b.barcodes[i].first
        endBar = b.barcodes[i].second
          index = ceil((beginBar-bmin)/(dx/2))
         while ( result[index].first < beginBar )index += 1
         while ( result[index].first < beginBar )--index
        height = 0
         # I know this is silly to add dx/100000 but this is neccesarry to make it work. Othervise, because of roundoff error, the program gave wrong results. It took me a while to track this.
         while (  height <= ((endBar-beginBar)/2.0) )
             # go up
             result[index].second.push_back( height )
             height += dx/2
             index += 1
         end
         height -= dx
         while ( (height >= 0)  )
             # go down
             result[index].second.push_back( height )
             height -= dx/2
             index += 1
         end
     end
     # println("All barcodes has been added to the mesh")
     indexOfLastNonzeroLandscape = 0
     i = 0
     for  x = bmin : bmax 
         sort( result[i].second.begin() , result[i].second.end() , greater<double>() )
         if ( result[i].second.size() > indexOfLastNonzeroLandscape )indexOfLastNonzeroLandscape = result[i].second.size()
         i += 1
     end
     if ( local_dbg )println("Now we fill in the suitable vecors in this landscape")end
     vector< vector< std::pair > > land(indexOfLastNonzeroLandscape)
     for  dim = 0 : indexOfLastNonzeroLandscape 
         land[dim].push_back( make_pair( INT_MIN,0 ) )
     end
     i = 0
     for  x = bmin : bmax 
         for nr = 0 : result[i].second.size() 
              land[nr].push_back(make_pair( result[i].first , result[i].second[nr] ))
         end
         i += 1
     end
     for  dim = 0 : indexOfLastNonzeroLandscape 
         land[dim].push_back( make_pair( INT_MAX,0 ) )
     end
     land.land.clear()
     land.land.swap(land)
     land.reduceAlignedPoints()
end

function multiplyByIndicatorFunction(land::PersistenceLandscape, vector<pair > indicator ; local_dbg = false)
    PersistenceLandscape result
    for dim = 0 : size(land,1) 
        if(local_dbg)println("dim : $(dim)")end
        lambda_n = MyPair[]
        push!(lambda_n,  make_pair( 0 , INT_MIN ) )
        if indicator.size() > dim
            if (local_dbg)
                println("There is nonzero indicator in this dimension")
                println("[ $(indicator[dim].first) $(indicator[dim].second)]")
            end
            for nr = 0 : land.land[dim].size() 
                if (local_dbg)
                    cout << "land.land[dim][nr] : $(this->land[dim][nr].first) $(this->land[dim][nr].second)"
                end
                if land.land[dim][nr].first < indicator[dim].first
                    if (local_dbg)
                        cout << "Below treshold"
                    end
                    continue
                end
                if land.land[dim][nr].first > indicator[dim].second
                    if (local_dbg)println("Just pass above treshold")end
                    push!(lambda_n,  make_pair( indicator[dim].second , functionValue ( land.land[dim][nr-1] , this->land[dim][nr] , indicator[dim].second ) ) )
                    push!(lambda_n,  make_pair( indicator[dim].second , 0 ) )
                    break
                end
                if (land.land[dim][nr].first >= indicator[dim].first) && (this->land[dim][nr-1].first <= indicator[dim].first)
                    if (local_dbg)
                        cout << "Entering the indicator"
                    end
                    push!(lambda_n,  make_pair( indicator[dim].first , 0 ) )
                    push!(lambda_n,  make_pair( indicator[dim].first , functionValue(land.land[dim][nr-1],this->land[dim][nr],indicator[dim].first) ) )
                end
                if (local_dbg)
                    cout << "We are here"
                end
                push!(lambda_n,  make_pair( land.land[dim][nr].first , this->land[dim][nr].second ) )
            end
        end
        push!(lambda_n,  make_pair( 0 , INT_MIN ) )
        if lambda_n.size() > 2
            result.land.push_back( lambda_n )
        end
    end
    return result
end


# TODO -- removewhen the problem is respved
function check( i::UInt, vector< pair > v )
    if i < 0) || (i >= v.size()
        println("you want to get to index : $(i) $(v.size()) indices")
        cin.ignore()
        return true
    end
    return false
end

function computeIntegralOfLandscape(land::PersistenceLandscape,)const
   result = 0
    for i = 0 : size(land,1) 
        for nr = 2 : land.land[i].size()-1 
            # it suffices to compute every planar integral and then sum them ap for each lambda_n
            result += 0.5*( land.land[i][nr].first - this->land[i][nr-1].first )*(this->land[i][nr].second + this->land[i][nr-1].second)
        end
    end
    return result
end

function computeIntegralOfLandscape(land::PersistenceLandscape, p::Float64; local_dbg = false)
   result = 0
    for i = 0 : size(land,1)
        for nr = 2 : land.land[i].size()-1
            if (local_dbg)println("nr : $(nr)")
            # In this interval, the landscape has a form f(x) = ax+b. We want to compute integral of (ax+b)^p = 1/a * (ax+b)^p+1end/(p+1)
            pair coef = computeParametersOfALine( land.land[i][nr] , this->land[i][nr-1] )
            a = coef.first
            b = coef.second
            if (local_dbg)println("($(land.land[i][nr].first),$(this->land[i][nr].second)) , $(this->land[i][nr-1].first) $(this->land[i][nr].second)))")

            land.land[i][nr].first == this->land[i][nr-1].first  && continue

            if a != 0
                result += 1/(a*(p+1)) * ( pow((a*land.land[i][nr].first+b),p+1) - pow((a*this->land[i][nr-1].first+b),p+1))
            else
                result += ( land.land[i][nr].first - this->land[i][nr-1].first )*( pow(this->land[i][nr].second,p) )
            end

            if local_dbg
                println("a : " <<a << " , b : $(b)")
                println("result : $(result)")
            end
        end
        # if (local_dbg) cin.ignore()
    end
    return result
end

function computeIntegralOfLandscapeMultipliedByIndicatorFunction(land::PersistenceLandscape, vector<pair > indicator )const
    PersistenceLandscape l = land.multiplyByIndicatorFunction(indicator)
    return l.computeIntegralOfLandscape()
end

function computeIntegralOfLandscapeMultipliedByIndicatorFunction(land::PersistenceLandscape, vector<pair > indicator , p::Float64 )const# this function compute integral of p-th power of landscape.
    PersistenceLandscape l = land.multiplyByIndicatorFunction(indicator)
    return l.computeIntegralOfLandscape(p)
end

# This is a standard function which pairs maxima and minima which are not more than epsilon apart.
# This algorithm do not reduce all of them, just make one passage through data. In order to reduce all of them
# use the function reduceAllPairsOfLowPersistenceMaximaMinima(epsilon )
# WARNING! THIS PROCEDURE MODIFIES THE LANDSCAPE!!!
function removePairsOfLocalMaximumMinimumOfEpsPersistence(land::PersistenceLandscape, epsilon::Float64)
    numberOfReducedPairs = 0
    for dim = 0  : size(land,1)
        ( 2 > land.land[dim].size()-3 ) && continue #  to make sure that the loop in below is not infinite.
        for nr = 2 : land.land[dim].size()-3
            if (abs(land.land[dim][nr].second - this->land[dim][nr+1].second) < epsilon)
                &&
                (this->land[dim][nr].second != this->land[dim][nr+1].second)
                # right now we modify only the lalues of a points. That means that angles of lines in the landscape changes a bit. This is the easiest computational
                # way of doing this. But I am not sure if this is the best way of doing such a reduction of nonessential critical points. Think about this!
                if land.land[dim][nr].second < this->land[dim][nr+1].second
                    land.land[dim][nr].second = this->land[dim][nr+1].second
                else
                    land.land[dim][nr+1].second = this->land[dim][nr].second
                end
                numberOfReducedPairs += 1
            end
        end
    end
    return numberOfReducedPairs
end

# this procedure redue all critical points of low persistence.
function reduceAllPairsOfLowPersistenceMaximaMinima(land::PersistenceLandscape,epsilon )
    numberOfReducedPoints = 1
    while ( numberOfReducedPoints )
        numberOfReducedPoints = land.removePairsOfLocalMaximumMinimumOfEpsPersistence( epsilon )
    end
end

# It may happened that some landscape points obtained as a aresult of an algorithm lies in a line. In this case, the following procedure allows to
# remove unnecesary points.
function reduceAlignedPoints(land::PersistenceLandscape,tollerance; local_debug = false)# this parapeter says how much the coeficients a and b in a formula y=ax+b may be different to consider points aligned.
    for dim = 0  : size(land,1) 
         nr = 1
        lambda_n = MyPair[]
        push!(lambda_n,  land.land[dim][0] )
        while ( nr != land.land[dim].size()-2 )
            # first, compute a and b in formula y=ax+b of a line crossing land.land[dim][nr] and this->land[dim][nr+1].
            pair res = computeParametersOfALine( land.land[dim][nr] , this->land[dim][nr+1] )
            if local_debug
                println("Considering points : $(land.land[dim][nr]) and $(this->land[dim][nr+1])")
                println("Adding : $(land.land[dim][nr] << " to lambda_n.")")
            end
            push!(lambda_n,  land.land[dim][nr] )
            a = res.first
            b = res.second
            int i = 1
            while ( nr+i != land.land[dim].size()-2 )
                if local_debug
                    println("Checking if : $(land.land[dim][nr+i+1] << " is aligned with them ")")
                end
                pair res1 = computeParametersOfALine( land.land[dim][nr] , this->land[dim][nr+i+1] )
                if (abs(res1.first-a) < tollerance) && (abs(res1.second-b)<tollerance)
                    local_debug && println("It is aligned ")end
                    i += 1
                end
                    local_debug && println("It is NOT aligned ")end
                    break
                end
            end
            local_debug && println("We are out of the while loop. The number of aligned points is : $(i)") # std::cin.ignore())")
            end
            nr += i
        end
        if local_debug
            println("Out  of main while loop, done with this dimension ")
            println("Adding : $(land.land[dim][ this->land[dim].size()-2 ] << " to lamnda_n ")")
            println("Adding : $(land.land[dim][ this->land[dim].size()-1 ] << " to lamnda_n ")")
            cin.ignore()
        end

        push!(lambda_n,  land.land[dim][ this->land[dim].size()-2 ] )
        push!(lambda_n,  land.land[dim][ this->land[dim].size()-1 ] )
        # if something was reduced, then replace land.land[dim] with the new lambda_n.

        if lambda_n.size() < land.land[dim].size()
            if lambda_n.size() > 4
                land.land[dim].swap(lambda_n)
            end
        end
    end
end

# Yet another function to smooth up the data. The idea of this one is as follows. Let us take a landscape point A which is not (+infty,0), (-infty,0) of (a,0), (b,0), where a and b denotes the
# points which support of the function begins and ends. Let B and C will be the landscape points after A. Suppose B and C are also no one as above.
# The question we are asking here is -- can we remove the point B and draw a line from A to C such that the difference in a landscape will be not greater than epsilon?
# To measure the penalty of removing B, the funcion penalty. In below, the simplese example is given:
function penalty(pair A,pair B, std::pair C)
    return abs(functionValue(A,C,B.first)-B.second)
end# penalty

function reducePoints(tollerance ,(*penalty)(pair ,pair,std::pair) ; local_debug = false)::PersistenceLandscape
    numberOfPointsReduced = 0
    for dim = 0  : size(land,1)
        nr = 1
        lambda_n = MyPair[]
        local_debug && println("Adding point to lambda_n : $(land.land[dim][0])")
        push!(lambda_n,  land.land[dim][0] )
        while ( nr <= land.land[dim].size()-2 )
            local_debug && println("Adding point to lambda_n : $(land.land[dim][nr])")
            push!(lambda_n,  land.land[dim][nr] )
            if penalty( land.land[dim][nr],this->land[dim][nr+1],this->land[dim][nr+2] ) < tollerance
                nr += 1
                numberOfPointsReduced += 1
            end
            nr += 1
        end
        local_debug && println("Adding point to lambda_n : $(land.land[dim][nr])")
        local_debug && println("Adding point to lambda_n : " <<land.land[dim][nr])
        push!(lambda_n,  land.land[dim][ this->land[dim].size()-2 ] )
        push!(lambda_n,  land.land[dim][ this->land[dim].size()-1 ] )
        # if something was reduced, then replace land.land[dim] with the new lambda_n.
        if lambda_n.size() < land.land[dim].size()
            if lambda_n.size() > 4
                # CHANGE
                # land.land[dim] = lambda_n
                land.land[dim].swap(lambda_n)
            end
            else
                land.land[dim].clear()
            end
        end
    end
    return numberOfPointsReduced
end

function findZeroOfALineSegmentBetweenThoseTwoPoints ( p1::MyPair, p2::MyPair )
    if ( p1.first == p2.first )return p1.first
    if p1.second*p2.second > 0
        ostringstream errMessage
        errMessage("In function findZeroOfALineSegmentBetweenThoseTwoPoints the agguments are: ($(p1.first)),$(p1.second)) and ($(p2.first), $(p2.second)). There is no zero in line between those two points. Program terminated.")
        string errMessageStr = errMessage.str()
        char* err = errMessageStr.c_str()
        throw(err)
    end
    # we assume here, that x \in [ p1.first, p2.first ] and p1 and p2 are points between which we will put the line segment
    a = (p2.second - p1.second)/(p2.first - p1.first)
    b = p1.second - a*p1.first
    # println("Line crossing points : ($(p1.first << ",$(p1.second)) oraz (" << p2.first) $(p2.second)) :")")
    # println("a : $(a) $(b) , x : $(x)")
    return -b/a
end

# this is O(log(n)) algorithm, where n is number of points in land.land.
bool computeValueAtAGivenPointDbg = false
function computeValueAtAGivenPoint(land::PersistenceLandscape, level::UInt, x::Float64 )const
    # in such a case lambda_level = 0.
    if ( level > size(land,1) ) return 0
    # we know that the points in land.land[level] are ordered according to x coordinate. Therefore, we can find the point by using bisection:
    coordBegin = 1
    coordEnd = land.land[level].size()-2
    if computeValueAtAGivenPointDbg
        println("Tutaj")
        println("x : $(x)")
        println("land.land[level][coordBegin].first : $(this->land[level][coordBegin].first)")
        println("land.land[level][coordEnd].first : $(this->land[level][coordEnd].first)")
    end
    # in this case x is outside the support of the landscape, therefore the value of the landscape is 0.
    if ( x <= land.land[level][coordBegin].first )return 0
    if ( x >= land.land[level][coordEnd].first )return 0
    if (computeValueAtAGivenPointDbg)println("Entering to the while loop")
    while ( coordBegin+1 != coordEnd )
        if (computeValueAtAGivenPointDbg)
            println("coordBegin : $(coordBegin)")
            println("coordEnd : $(coordEnd)")
            println("land.land[level][coordBegin].first : $(this->land[level][coordBegin].first)")
            println("land.land[level][coordEnd].first : $(this->land[level][coordEnd].first)")
        end
        newCord = (unsigned)floor((coordEnd+coordBegin)/2.0)
        if (computeValueAtAGivenPointDbg)
            println("newCord : $(newCord)")
            println("land.land[level][newCord].first : $(this->land[level][newCord].first)")
            cin.ignore()
        end
        if land.land[level][newCord].first <= x
            coordBegin = newCord
            if ( land.land[level][newCord].first == x )return this->land[level][newCord].second
        end
        else
            coordEnd = newCord
        end
    end
    if (computeValueAtAGivenPointDbg)
        println("x : $(x) is between : $(land.land[level][coordBegin].first) $(this->land[level][coordEnd].first))")
        println("the y coords are : $(land.land[level][coordBegin].second) $(this->land[level][coordEnd].second)")
        println("coordBegin : $(coordBegin)")
        println("coordEnd : $(coordEnd)")
        cin.ignore()
    end
    return functionValue( land.land[level][coordBegin] , this->land[level][coordEnd] , x )
end
# Operations on landscapes <<<
# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-


# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-
# Other functions  >>>

function computeParametersOfALine( p1::MyPair , std::p2::MyPair )
    # p1.second = a*p1.first + b => b = p1.second - a*p1.first
    # p2.second = a*p2.first + b = a*p2.first + p1.second - a*p1.first = p1.second + a*( p2.first - p1.first )
    # =>
    # (p2.second-p1.second)/( p2.first - p1.first )  = a
    # b = p1.second - a*p1.first.
    a = (p2.second-p1.second)/( p2.first - p1.first )
    b = p1.second - a*p1.first
    return make_pair(a,b)
end

# Other functions <<<
# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-



ostream& operator<<(ostream& out,land::PersistenceLandscape)
    for level = 0 : land.land.size()
        out << "Lambda_" << level << ":"
        for i = 0 : land.land[level].size()
            if land.land[level][i].first == INT_MIN
                out << "-inf"
            end
                if land.land[level][i].first == INT_MAX
                    out << "+inf"
                end
                    out << land.land[level][i].first
                end
            end
            out << " , " << land.land[level][i].second
        end
    end
    return out
end

function multiplyLanscapeByRealNumberOverwrite(land::PersistenceLandscape, x::Float64 )
    for dim = 0 : size(land,1) 
        for i = 0 : land.land[dim].size() 
             land.land[dim][i].second *= x
        end
    end
end


function abs(;local_debug = false)
    PersistenceLandscape result
    for level = 0 : size(land,1)
        if ( local_debug ) println("level: $(level)") end
        lambda_n = MyPair[]
        push!(lambda_n,  make_pair( INT_MIN , 0 ) )
        for i = 1 : land.land[level].size() 
            if ( local_debug )println("land.land[$(level) $(i)] : $(this->land[level][i])")end
            # if a line segment between land.land[level][i-1] and this->land[level][i] crosses the x-axis, then we have to add one landscape point t oresult
            if (land.land[level][i-1].second)*(this->land[level][i].second)  < 0
               zero = findZeroOfALineSegmentBetweenThoseTwoPoints( land.land[level][i-1] , this->land[level][i] )
                push!(lambda_n,  make_pair(zero , 0) )
                push!(lambda_n,  make_pair(land.land[level][i].first , abs(this->land[level][i].second)) )
                if local_debug
                    println("Adding pair : ($(zero << ",0)")")
                    println("In the same step adding pair : ($(land.land[level][i].first) $(abs(this->land[level][i].second))) ")
                    cin.ignore()
                end
            else
                push!(lambda_n,  make_pair(land.land[level][i].first , abs(this->land[level][i].second)) )
                if local_debug
                    println("Adding pair : ($(land.land[level][i].first) $(abs(this->land[level][i].second))) ")
                    cin.ignore()
                end
            end
        end
        push!(result_land,  lambda_n )
    end
    return result
end

function multiplyLanscapeByRealNumberNotOverwrite(land:PersistenceLandsdcape, x::Real )
    result = Any[]
    for dim = 0 : size(land,1)
        lambda_dim = MyPair[]
        for i = 0 : land.land[dim].size() 
            push!(lambda_dim, make_pair( land.land[dim][i].first , x*this->land[dim][i].second ))
        end

        push!(result, lambda_dim)
    end
    # CHANGE
    # res.land = result
    return PersistenceLandscape(res, land.dimension)
end# multiplyLanscapeByRealNumberOverwrite


# original function took arguments which were m,odified in the function. Now it returns values required
# function computeMaximalDistanceNonSymmetric( pl1::PersistenceLandscape, pl2::PersistenceLandscape , nrOfLand::UInt , x::Float64, y1::Float64, y2::Float64)::PersistenceLandscape
function computeMaximalDistanceNonSymmetric( pl1::PersistenceLandscape, pl2::PersistenceLandscape)# , nrOfLand::UInt , x::Float64, y1::Float64, y2::Float64)
    # this distance is not symmetric. It compute ONLY distance between inflection points of pl1 and pl2.
   maxDist = 0
    int minimalNumberOfLevels = min( size(pl1.land,1) , pl2.land.size() )
    for level = 1 : minimalNumberOfLevels 
        p2Count = 0
        for i = 1 : size(l1.land[level],1)-1  # w tym przypadku nie rozwarzam punktow w nieskocznosci
            while ( true )
                if (
                    (pl1.land[level][i].first>=pl2.land[level][p2Count].first)
                    &&
                    (pl1.land[level][i].first<=pl2.land[level][p2Count+1].first)
                   )
                    break
                end
                p2Count += 1
            end
           val = abs(
                     functionValue(pl2.land[level][p2Count],
                                   pl2.land[level][p2Count+1],
                                   pl1.land[level][i].first
                                  ) - pl1.land[level][i].second
                    )
            # println("functionValue( pl2.land[level][p2Count] , pl2.land[level][p2Count+1] , pl1.land[level][i].first ) : $(functionValue( pl2.land[level][p2Count] , pl2.land[level][p2Count+1] , pl1.land[level][i].first ))")
            # println("pl1.land[level][i].second : $(pl1.land[level][i].second)")
            # println("pl1.land[level][i].first :$(pl1.land[level][i].first)")
            # cin.ignore()
            if maxDist <= val
                maxDist = val
                nrOfLand = level
                x = pl1.land[level][i].first
                y1 = pl1.land[level][i].second
                y2 = functionValue( pl2.land[level][p2Count] , pl2.land[level][p2Count+1] , pl1.land[level][i].first )
            end
       end
    end
    if minimalNumberOfLevels < size(pl1.land,1)
        for level = minimalNumberOfLevels : size(pl1.land,1)
            for i = 1 : psize(l1.land[level]) 
                if maxDist < pl1.land[level][i].second
                    maxDist = pl1.land[level][i].second
                    nrOfLand = level
                    x = pl1.land[level][i].first
                    y1 = pl1.land[level][i].second
                    y2 = 0
                end
            end
        end
    end
    return maxDist, nrOfLand, x, y1, y2
end

function computeMaxNormDiscanceOfLandscapes(first, second, nrOfLand , x::Float64, y1::Float64, y2::Float64)::PersistenceLandscape

    dFirst, nrOfLandFirst, xFirst, y1First, y2First = computeMaximalDistanceNonSymmetric(first,second)
    #,nrOfLandFirst,xFirst, y1First, y2First)

    dSecond, nrOfLandSecond, xSecond, y1Second, y2Second= computeMaximalDistanceNonSymmetric(second,first)
    #,nrOfLandSecond,xSecond, y1Second, y2Second)

    if dFirst > dSecond
        nrOfLand = nrOfLandFirst
        x = xFirst
        y1 = y1First
        y2 = y2First
    else
        nrOfLand = nrOfLandSecond
        x = xSecond
        # this twist in below is neccesary!
        y2 = y1Second
        y1 = y2Second
        # y1 = y1Second
        # y2 = y2Second
    end
    return max(dFirst, dSecond)
end

function computeMaximalDistanceNonSymmetric(pl1::PersistenceLandscape, pl2::PersistenceLandscape; dbg = false)
    dbg && println(" computeMaximalDistanceNonSymmetric")

    # this distance is not symmetric. It compute ONLY distance between inflection points of pl1 and pl2.
    maxDist = 0
    minimalNumberOfLevels = min( size(pl1.land) , size(pl2.land))
    for  level = 1 : minimalNumberOfLevels
        if (dbg)
            println("Level : $(level)")
            println("PL1 :")
            for i = 0 : psize(l1.land[level]) 
                println("($(pl1.land[level][i].first),$(pl1.land[level][i].second))")
            end
            println("PL2 :")
            for i = 0 : psize(l2.land[level])
                println("($(pl2.land[level][i].first),$(pl2.land[level][i].second))")
            end
            # cin.ignore()
        end

        p2Count = 0
        for i = 1 : size(l1.land[level],1)-1  # w tym przypadku nie rozwarzam punktow w nieskocznosci
            while ( true )
                if (pl1.land[level][i].first >= pl2.land[level][p2Count].first)
                    &&
                    (pl1.land[level][i].first <= pl2.land[level][p2Count+1].first)
                    break
                end
                p2Count += 1
            end
            val = abs(
                     functionValue(pl2.land[level][p2Count],
                                   pl2.land[level][p2Count+1],
                                   pl1.land[level][i].first
                                  ) - pl1.land[level][i].second
                    )
            if maxDist <= val
                maxDist = val
            end

            if (dbg)
                println(pl1.land[level][i].first <<"in [$(pl2.land[level][p2Count].first),$( pl2.land[level][p2Count+1].first)]")")
                println("pl1[level][i].second : $(pl1.land[level][i].second)")
                println("functionValue( pl2[level][p2Count] , pl2[level][p2Count+1] , pl1[level][i].first ) : $(functionValue( pl2.land[level][p2Count] , pl2.land[level][p2Count+1] , pl1.land[level][i].first ))")
                println("val : $(val))
                # cin.ignore()
            end
        end
    end

    dbg && println("minimalNumberOfLevels : $(minimalNumberOfLevels)")

    if minimalNumberOfLevels < size(pl1.land,1)
        for level = minimalNumberOfLevels : size(pl1.land,1)
            for i = 1 : size(l1.land[level],1)
                dbg && println("pl1[level][i].second  : $(pl1.land[level][i].second)")
                if  maxDist < pl1.land[level][i].second
                    maxDist = pl1.land[level][i].second
                end
            end
        end
    end
    return maxDist
end

function computeDiscanceOfLandscapes(first::PersistenceLandscape ,second::PersistenceLandscape, p::UInt)
    # This is what we want to compute: (\int_- \inftyend^+\inftyend| first-second |^p)^(1/p). We will do it one step at a time:
    # first-second :
    lan = first-second
    # | first-second |:
    lan = abs(lan)
    # \int_- \inftyend^+\inftyend| first-second |^p
    if p != 1
        result = computeIntegralOfLandscape(lan, p)
    else
        result = computeIntegralOfLandscape(lan)
    end

    # (\int_- \inftyend^+\inftyend| first-second |^p)^(1/p)
    return result^(1/p )
end

function computeMaxNormDiscanceOfLandscapes(first::PersistenceLandscape, second::PersistenceLandscape)::PersistenceLandscape
    @warn "This function may not work, as max is not defined for PersistenceLandscape structure"
    return max(
               computeMaximalDistanceNonSymmetric(first,second),
               computeMaximalDistanceNonSymmetric(second,first)
              )
end

function comparePairsForMerging(first::MyPair, second::MyPair )
    return (first.first < second.first)
end

function generateBettiNumbersHistogram(land::PersistenceLandscape ;dbg = false)::PersistenceLandscape
    resultRaw = MyPair[]

    for dim = 0 : size(land,1)
        rangeOfLandscapeInThisDimension = MyPair[]
        if dim > 0
            for i = 1 :size(land.land[dim])-1 
                if land.land[dim][i].second == 0
                    push!(rangeOfLandscapeInThisDimension, make_pair(land.land[dim][i].first , dim+1))
                end
            end
        else
            # dim == 0.
            first = true
            for i = 1 : size(land.land[dim],1)-1
                if land.land[dim][i].second == 0
                    if first
                        push!(rangeOfLandscapeInThisDimension, make_pair(
                                                                         land.land[dim][i].first,
                                                                         0)
                             )
                    end
                    push!(rangeOfLandscapeInThisDimension, make_pair(
                                                                     land.land[dim][i].first,
                                                                     dim+1)
                         )
                    if ( !first )
                        push!(rangeOfLandscapeInThisDimension, make_pair(
                                                                         land.land[dim][i].first,
                                                                         0)
                             )
                    end
                    first = !first
                end
            end
        end
        # vector< std::pair<, unsigned > > resultRawNew( resultRaw.size() + rangeOfLandscapeInThisDimension.size() )
        resultRawNew = MyPair[]

        resultRaw = sort(
                         vcat(resultRaw.begin(),
                            resultRaw.end(),
                            rangeOfLandscapeInThisDimension.begin(),
                            rangeOfLandscapeInThisDimension.end(),
                            resultRawNew.begin()
                        ),
                        comparePairsForMerging)

        resultRawNew = copy(resultRaw)
        if dbg
            println("Raw result : for dim : $(dim)")
            for i = 0 : resultRaw.size() 
                println("($(resultRaw[i].first) $(resultRaw[i].second))")
            end
            # getchar()
        end
    end
    if dbg
        println("Raw result : ")
        for i = 0 : resultRaw.size() 
            println("($(resultRaw[i].first) $(resultRaw[i].second))")
        end
        # getchar()
    end

    # now we should make it into a step function by adding a points in the jumps:
    result = MyPair[]

    resultRaw.size() == 0 && return result

    for i = 1 : size(resultRaw)
        push!(result,  resultRaw[i-1] )
        if resultRaw[i-1].second <= resultRaw[i].second
            push!(result,  make_pair( resultRaw[i].first , resultRaw[i-1].second ) )
        else
            push!(result,  make_pair( resultRaw[i-1].first , resultRaw[i].second ) )
        end
    end
    # result.erase( unique( result.begin(), result.end() ), result.end() )
    result = unique(result)

    resultNew = MyPair[]
    i = 1
    while ( i != result.size() )
        x = result[i].first
        maxBetti = result[i].second
        minBetti = result[i].second
        while ( (i != result.size()) && (abs(result[i].first - x) < 0.000001) )
            ( maxBetti < result[i].second ) && maxBetti = result[i].second
            if ( minBetti > result[i].second ) && minBetti = result[i].second
            i += 1
        end
        if minBetti != maxBetti
            if (resultNew.size() == 0) || (resultNew[resultNew.size()-1].second <= minBetti)
                # going up
                push!(resultNew,  make_pair( x , minBetti ) )
                push!(resultNew,  make_pair( x , maxBetti ) )
            else
                # going down
                push!(resultNew,  make_pair( x , maxBetti ) )
                push!(resultNew,  make_pair( x , minBetti ) )
            end
        else
            push!(resultNew,  make_pair( x , minBetti ) )
        end
    end

    result = resultNew
    if dbg
        println("Final result : ")
        for i = 0 : result.size() 
            println("($(result[i].first) $(result[i].second))")
        end
        # getchar()
    end
    return result
end# generateBettiNumbersHistogram


function computeInnerProduct(l1::PersistenceLandscape, l2::PersistenceLandscape; dbg = true)
    result = 0
    for level = 1 : min( size(l1) , size(l2) )
        dbg && println("Computing inner product for a level : $(level;)")

        if ( size(l1.land[level]) * size(l2.land[level]) == 0 )
            continue
        end
        # endpoints of the interval on which we will compute the inner product of two locally linear functions:
        x1 = -Inf
        x2 = 0;
        if l1.land[level][1].first < l2.land[level][1].first
            x2 = l1.land[level][1].first
        else
            x2 = l2.land[level][1].first
        end
        # iterators for the landscapes l1 and l2

        l1It = 0
        l2It = 0
        while ( (l1It < size(l1.land[level])-1) && (l2It < size(l2.land[level])-1) )
            # compute the value of a inner product on a interval [x1,x2]
            a = (l1.land[level][l1It+1].second - l1.land[level][l1It].second)/(l1.land[level][l1It+1].first - l1.land[level][l1It].first)

            b = l1.land[level][l1It].second - a*l1.land[level][l1It].first

            c = (l2.land[level][l2It+1].second - l2.land[level][l2It].second)/(l2.land[level][l2It+1].first - l2.land[level][l2It].first)

            d = l2.land[level][l2It].second - c*l2.land[level][l2It].first

            contributionFromThisPart = (a*c*x2*x2*x2/3 + (a*d+b*c)*x2*x2/2 + b*d*x2) - (a*c*x1*x1*x1/3 + (a*d+b*c)*x1*x1/2 + b*d*x1)

            result += contributionFromThisPart
            if dbg
                println("[l1.land[level][l1It].first,l1.land[level][l1It+1].first] : $(l1.land[level][l1It].first), $(l1.land[level][l1It+1].first)")
                println("[l2.land[level][l2It].first,l2.land[level][l2It+1].first] : $(l2.land[level][l2It].first), $(l2.land[level][l2It+1].first)")
                println("a : $(a), b : $(b), c: $(c), d : $()d)")
                println("x1 : $(x1) , x2 : $(x2)")
                println("contributionFromThisPart : $(contributionFromThisPart)")
                println("result : $(result)")
                # getchar()
            end
            # we have two intervals in which functions are constant:
            # [l1.land[level][l1It].first , l1.land[level][l1It+1].first]
            # and
            # [l2.land[level][l2It].first , l2.land[level][l2It+1].first]
            # We also have an interval [x1,x2]. Since the intervals in the landscapes cover the whole R, then it is clear that x2
            # is either l1.land[level][l1It+1].first of l2.land[level][l2It+1].first or both. Lets test it.

            if x2 == l1.land[level][l1It+1].first
                if x2 == l2.land[level][l2It+1].first
                    # in this case, we increment both:
                    l2It += 1
                    dbg && println("Incrementing both")
                else
                    dbg && println("Incrementing first")
                end
                l1It += 1
            else
                # in this case we increment l2It
                l2It += 1
                dbg && println("Incrementing second")
            end
            # Now, we shift x1 and x2:
            x1 = x2
            if l1.land[level][l1It+1].first < l2.land[level][l2It+1].first
                x2 = l1.land[level][l1It+1].first
            else
                x2 = l2.land[level][l2It+1].first
            end
        end
    end
    return result
end

# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-
# File operations >>>

# function printToFiles(land::PersistenceLandscape, char* filename , from::UInt, unsigned to )const
#     # if ( from > to )throw("Error printToFiles printToFile( char* filename , from::UInt, unsigned to ). 'from' cannot be greater than 'to'.")
#     # # if ( to > size(land,1) )throw("Error in printToFiles( char* filename , from::UInt, unsigned to ). 'to' is out of range.")
#     # if ( to > size(land,1) )to = size(land,1);end
#     # ofstream write
#     # for dim = from :to 
#     #     ostringstream name
#     #     name << filename << "_" << dim << ".dat"
#     #     string fName = name.str()
#     #     char* FName = fName.c_str()
#     #     write.open(FName)
#     #     write << "#lambda_" << dim
#     #     for i = 1 : land.land[dim].size()-1 
#     #         write << land.land[dim][i].first << "  " << this->land[dim][i].second
#     #     end
#     #     write.close()
#     # end
# end
#
# function printToFiles(land::PersistenceLandscape, char* filename, int numberOfElementsLater ,  ... )const
#   # va_list arguments
#   # va_start ( arguments, numberOfElementsLater )
#   # ofstream write
#   # for ( int x = 0; x < numberOfElementsLater; x ) += 1
#   #      dim = va_arg ( arguments, unsigned )
#   #      if ( dim > size(land,1) )throw("In function generateGnuplotCommandToPlot(char* filename,int numberOfElementsLater,  ... ), one of the number provided is greater than number of nonzero landscapes")
#   #       ostringstream name
#   #      name << filename << "_" << dim << ".dat"
#   #      string fName = name.str()
#   #      char* FName = fName.c_str()
#   #      write.open(FName)
#   #      write << "#lambda_" << dim
#   #      for i = 1 : land.land[dim].size()-1 
#   #          write << land.land[dim][i].first << "  " << this->land[dim][i].second
#   #      end
#   #      write.close()
#   # end
#   # va_end ( arguments )
# end
#
# function printToFiles(land::PersistenceLandscape, char* filename )const
#     # land.printToFiles(filename , (unsigned)0 , (unsigned)size(land,1) )
# end
#
# function printToFile(land::PersistenceLandscape, char* filename , from::UInt, unsigned to )const
#     # if ( from > to )throw("Error in printToFile( char* filename , from::UInt, unsigned to ). 'from' cannot be greater than 'to'.")
#     # if ( to > size(land,1) )throw("Error in printToFile( char* filename , from::UInt, unsigned to ). 'to' is out of range.")
#     # ofstream write
#     # write.open(filename)
#     # write << land.dimension
#     # for dim = from : to 
#     #     write << "#lambda_" << dim
#     #     for i = 1 : land.land[dim].size()-1 
#     #         write << land.land[dim][i].first << "  " << this->land[dim][i].second
#     #     end
#     # end
#     # write.close()
# end
#
# function printToFile(land::PersistenceLandscape, char* filename  )const
#     # land.printToFile(filename,0,size(land,1))
# end

# ===-===-===-===-
# GNUplots >>>
# function generateGnuplotCommandToPlot(land::PersistenceLandscape, char* filename, from::UInt, unsigned to )const
#     # function body removed
# end
#
# function generateGnuplotCommandToPlot(land::PersistenceLandscape,char* filename,int numberOfElementsLater,  ... )const
#     # function body removed
# end
#
# function generateGnuplotCommandToPlot(land::PersistenceLandscape, char* filename )const
#     # function body removed
# end


# function printBettiNumbersHistoramIntoFileAndGenerateGnuplotCommand(land::PersistenceLandscape, char* filename )const
#     vector< std::pair<, > > histogram = land.generateBettiNumbersHistogram()
#     ostringstream result
#     for i = 0 : histogram.size() 
#         result << histogram[i].first << " " << histogram[i].second
#     end
#     ofstream write
#     write.open( filename )
#     write << result.str()
#     write.close()
#     println("The result is in the file : $(filename) . Now in gnuplot type plot \"$(filename)\" with lines")
# end# printBettiNumbersHistoramIntoFileAndGenerateGnuplotCommand
# GNUplots <<<
# ===-===-===-===-

# function plot(land::PersistenceLandscape, char* filename ,  from,  to ,xRangeBegin ,xRangeEnd ,yRangeBegin ,yRangeEnd )
#
#     # this program create a gnuplot script file that allows to plot persistence diagram.
#     ofstream out
#
#     ostringstream nameSS
#     nameSS << filename << "_GnuplotScript"
#     string nameStr = nameSS.str()
#     out.open( (char*)nameStr.c_str() )
#
#     if (xRangeBegin != -1) || (xRangeEnd != -1) || (yRangeBegin != -1) || (yRangeEnd != -1) 
#         out << "set xrange [$(xRangeBegin) $(xRangeEnd)]"
#         out << "set yrange [$(yRangeBegin) $(yRangeEnd)]"
#     end
#
#     if ( from == -1 )from = 0;end
#     if ( to == -1 )to = size(land,1);end
#
#     out << "plot "
#     for lambda= min(from,size(land,1)) : min(to,size(land,1)) 
#         out << "     '-' using 1:2 title 'l" << lambda << "' with lp"
#         if lambda+1 != min(to,size(land,1))
#             out << ", \\"
#         end
#         out
#     end
#
#     for lambda= min(from,size(land,1)) : min(to,size(land,1)) 
#         for i = 1 : land.land[lambda].size()-1 
#             out << land.land[lambda][i].first << " " << this->land[lambda][i].second
#         end
#         out << "EOF"
#     end
#     println("Gnuplot script to visualize persistence diagram written to the file: $(nameStr) $(nameStr)' in gnuplot to visualize.")
# end

# File operations <<<
# ===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-===-
