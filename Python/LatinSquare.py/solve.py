with open('input.txt') as f:
    lines = f.readlines()

lines = [x.strip() for x in lines]
i = 0
count = 0
w, h = 10, 10;
Matrix = [[0 for x in range(w)] for y in range(h)]

while i < len(lines):
    l = lines[i]
    if l.find("|") > 0:
        s = l.split("|")
        e = s[2].replace(" ", "")
        for j in xrange(0, len(e)):
            Matrix[count][j] = e[j]
            j= j +1
        count += 1
    i = i+1


for row in xrange(0,count):
    l = ""
    for col in xrange(0,count):
         l = l + Matrix[row][col]
    print(l)

done = 0
while done == 0:
    for row in xrange(0, count):
        for col in xrange(0, count):
            if Matrix[row][col] == '-':
                for col in xrange(0, count):
                    i
