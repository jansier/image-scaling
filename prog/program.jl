Pkg.add("Images")
using Images
using FileIO

# Transform RGBA color into a tuple
function colorToTuple(c)
    return float(red(c)), float(green(c)), float(blue(c))
end

# Transform a tuple into RGBA color
function tupleToColor(tuple)
    return RGBA{N0f8}(tuple[1], tuple[2], tuple[3], 1.0)
end

# Resize height using nearest neighbour method
function nearestNeighbourHeight(img, ny)
    mx, my = width(img), height(img)
    newImg = Array{typeof(img[1,1]), 2}(ny, mx)
    for i in 1:mx
        for j in 1:ny
            p_j = 1 + (j-1)*(my-1)/(ny-1)
            newImg[j, i] = img[trunc(Int, round(p_j)), i]
        end
    end
    newImg
end

# Resize width using nearest neighbour method
function nearestNeighbourWidth(img, nx)
    mx, my = width(img), height(img)
    newImg = Array{typeof(img[1,1]), 2}(my, nx)
    for i in 1:nx
        for j in 1:my
            p_i = 1 + (i-1)*(mx-1)/(nx-1)
            newImg[j, i] = img[j, trunc(Int, round(p_i))]
        end
    end
    newImg
end

# Resize with saving
function nearestNeighbourSave(file, nx, ny, heightFirst = true, outputFile = "neighbour_" * file)
    img = nearestNeighbour(load(file), nx, ny, heightFirst)
    save(outputFile, img)
    img
end

# Resize height first then width using nearest neighbour method
function nearestNeighbour(img, nx, ny, heightFirst = true)
    nx, ny = trunc(Int, nx), trunc(Int, ny)
    # TODO: Check if file is OK
    if(heightFirst)
        newHImg = nearestNeighbourHeight(img, ny)
        newImg = nearestNeighbourWidth(newHImg, nx)
    else
        newWImg = nearestNeighbourWidth(img, nx)
        newImg = nearestNeighbourHeight(newWImg, ny)
    end
    newImg
end

# Resize height using spline first method
function splineHeight(img, ny)
    mx, my = width(img), height(img)
    newImg = Array{typeof(img[1,1]), 2}(ny, mx)
    for i in 1:mx
        for j in 1:ny
            p_j = 1 + (j-1)*(my-1)/(ny-1)
            c1 = colorToTuple(img[trunc(Int, floor(p_j)), i])
            c2 = colorToTuple(img[trunc(Int, ceil(p_j)), i])
            c = tupleToColor(c1 .+ (p_j-trunc(Int, floor(p_j))) .* (c2.-c1))
            newImg[j, i] = c
        end
    end
    newImg
end

# Resize width using spline first method
function splineWidth(img, nx)
    mx, my = width(img), height(img)
    newImg = Array{typeof(img[1,1]), 2}(my, nx)
    for i in 1:nx
        for j in 1:my
            p_i = 1 + (i-1)*(mx-1)/(nx-1)
            c1 = colorToTuple(img[j, trunc(Int, floor(p_i))])
            c2 = colorToTuple(img[j, trunc(Int, ceil(p_i))])
            c = tupleToColor(c1 .+ (p_i-trunc(Int, floor(p_i))) .* (c2.-c1))
            newImg[j, i] = c
        end
    end
    newImg
end

# Resize with saving
function splineSave(file, nx, ny, heightFirst = true, outputFile = "spline_" * file)
    img = spline(load(file), nx, ny, heightFirst)
    save(outputFile, img)
    img
end

# Resize height first then width using spline first method
function spline(img, nx, ny, heightFirst = true)
    nx, ny = trunc(Int, nx), trunc(Int, ny)
    # TODO: Check if file is OK
    if(heightFirst)
        newHImg = splineHeight(img, ny)
        newImg = splineWidth(newHImg, nx)
    else
        newWImg = splineWidth(img, nx)
        newImg = splineHeight(newWImg, ny)
    end
    newImg
end

# Calculates value of spline for x, given the coefficients a,b,c,d and xj
spline3val(a,b,c,d,xj,x) = a .+ (b .* (x-xj)) .+ (c .* ((x-xj)*(x-xj))) .+ (d .* ((x-xj)*(x-xj)*(x-xj)))

# Make sure that color values are in range [0.0,1.0]
checkVal(t) = t > 1. ? 1. : (t < 0. ? 0. : t)

# Resize height using cubic spline method
function spline3Height(img, ny)
    mx, my = width(img), height(img)
    newImg = Array{typeof(img[1,1]),2}(ny, mx)
    for i = 1:mx
        a = Array{NTuple{3,Float64}}(my)
        b = Array{NTuple{3,Float64}}(my-1)
        c = Array{NTuple{3,Float64}}(my)
        d = Array{NTuple{3,Float64}}(my-1)

        α = Array{NTuple{3,Float64}}(my-1)
        l = Array{NTuple{3,Float64}}(my)
        m = Array{NTuple{3,Float64}}(my)
        z = Array{NTuple{3,Float64}}(my)

        for j = 1:my
            a[j] = colorToTuple(img[j,i])
        end

        for j = 2:(my-1)
            α[j] = 3 .* (a[j+1] .- a[j]) .- 3. .* (a[j] .- a[j-1])
        end

        l[1] = 1., 1., 1.
        m[1] = z[1] = 0., 0., 0.

        for j = 2:(my-1)
            l[j] = 4. .- m[j-1]
            m[j] = 1. ./ l[j]
            z[j] = (α[j] .- z[j-1]) ./ l[j]
        end

        l[my] = 1., 1., 1.
        z[my] = c[my] = 0., 0., 0.

        for j = (my-1):-1:1
            c[j] = z[j] .- (m[j] .* c[j+1])
            b[j] = a[j+1] .- a[j] .- ((c[j+1] .+ (2. .* c[j])) ./ 3.)
            d[j] = (c[j+1] .- c[j]) ./ 3.
        end

        for j = 1:ny
            p = trunc(Int, round(1 + (j-1)*(my-1)/(ny-1)))
            p = (p >= my) ? my-1 : p
            v = spline3val(a[p], b[p], c[p], d[p], p, 1 + (j-1)*(my-1)/(ny-1))
            col = (checkVal(v[1]), checkVal(v[2]), checkVal(v[3]))
            newImg[j,i] = tupleToColor(col)
        end
    end
    newImg
end

# Resize width using cubic spline method
function spline3Width(img, nx)
    mx, my = width(img), height(img)
    newImg = Array{typeof(img[1,1]),2}(my, nx)
    for i = 1:my
        a = Array{NTuple{3,Float64}}(mx)
        b = Array{NTuple{3,Float64}}(mx-1)
        c = Array{NTuple{3,Float64}}(mx)
        d = Array{NTuple{3,Float64}}(mx-1)

        α = Array{NTuple{3,Float64}}(mx-1)
        l = Array{NTuple{3,Float64}}(mx)
        m = Array{NTuple{3,Float64}}(mx)
        z = Array{NTuple{3,Float64}}(mx)

        for j = 1:mx
            a[j] = colorToTuple(img[i,j])
        end

        for j = 2:(mx-1)
            α[j] = 3 .* (a[j+1] .- a[j]) .- 3. .* (a[j] .- a[j-1])
        end

        l[1] = 1., 1., 1.
        m[1] = z[1] = 0., 0., 0.

        for j = 2:(mx-1)
            l[j] = 4. .- m[j-1]
            m[j] = 1. ./ l[j]
            z[j] = (α[j] .- z[j-1]) ./ l[j]
        end

        l[mx] = 1., 1., 1.
        z[mx] = c[mx] = 0., 0., 0.

        for j = (mx-1):-1:1
            c[j] = z[j] .- (m[j] .* c[j+1])
            b[j] = a[j+1] .- a[j] .- ((c[j+1] .+ (2. .* c[j])) ./ 3.)
            d[j] = (c[j+1] .- c[j]) ./ 3.
        end

        for j = 1:nx
            p = trunc(Int, round(1 + (j-1)*(mx-1)/(nx-1)))
            p = (p >= mx) ? mx-1 : p
            v = spline3val(a[p], b[p], c[p], d[p], p, 1 + (j-1)*(mx-1)/(nx-1))
            col = (checkVal(v[1]), checkVal(v[2]), checkVal(v[3]))
            newImg[i,j] = tupleToColor(col)
        end
    end
    newImg
end

# Resize height first then width using cubic spline method
function spline3(img, nx, ny, heightFirst = true)
    nx, ny = trunc(Int, nx), trunc(Int, ny)
    if (heightFirst)
        newHImg = spline3Height(img, ny)
        newImg  = spline3Width(newHImg, nx)
    else
        newWImg = spline3Width(img, nx)
        newImg  = spline3Height(newWImg, ny)
    end
    newImg
end

# Resize with saving
function spline3Save(file, nx, ny, heightFirst = true, outputFile = "spline3_" * file)
    img = spline3(load(file), nx, ny, heightFirst)
    save(outputFile, img)
    img
end
