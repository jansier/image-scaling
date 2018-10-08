include("program.jl")

# Create and save image of the difference
function differenceImage(img1, img2)
    w1, h1, w2, h2 = width(img1), height(img1), width(img2), height(img2)
    if((w1, h1) == (w2, h2))
        differenceImage = Array{typeof(img1[1,1]), 2}(h1, w1)
        for i in 1:w1
            for j in 1:h1
                c1 = colorToTuple(img1[j, i])
                c2 = colorToTuple(img2[j, i])
                c = tupleToColor(map(abs, c2 .- c1))
                differenceImage[j, i] = c
            end
        end
    else
        println("Error. Images must be of the same size")
        return
    end
    differenceImage
end

# Returns norm of an image
function imageNorm(img)
    w, h = width(img), height(img)
    norm = 0
    for i in 1:w
        for j in 1:h
            pixel = img[j, i]
            norm += float(red(pixel)) + float(green(pixel)) + float(blue(pixel))
        end
    end
    norm /= 3 * w * h
    norm
end
