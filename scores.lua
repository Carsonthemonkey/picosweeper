num_scores = 0
max_scores = 0
scores = {}
offset = 0
-- Cartdata must be initialized first
function init_scores(max_score_num, mem_offset)
    -- assert scores will fit in cartdata
    assert((max_scores * 4) + mem_offset + 1 < 64, "Failed to allocate in cart memory")
    scores = {}
    offset = mem_offset
    max_scores = max_score_num
    num_scores = dget(mem_offset)
    for i=mem_offset + 1, mem_offset + num_scores * 4, 4 do
        name = chr(dget(i)) .. chr(dget(i + 1)) .. chr(dget(i + 2))
        score = dget(i + 3)
        insert_score(name, score)
    end
end


-- Return true if the score would be in top saved scores
function is_high_score(score)
    if #scores < max_scores then
        return true
    end
    -- Compare to lowest
    lowest_idx = min(max_scores, #scores)
    print(scores[lowest_idx].val)
    return score > scores[lowest_idx].val
end

-- Add score sorted and save scores to cartdata
function add_score(name, score)
    assert(#name == 3, "Name must be 3 characters")
    if not is_high_score(score) then
        return
    end
    insert_score(name, score)
    save_scores()
end

-- Write scores to persistant cartdata
function save_scores() 
    -- set score number
    n = min(max_scores, #scores)
    dset(offset, n)
    for i=0,(n - 1) * 4, 4 do
        score = scores[(i / 4) + 1]
        ii = i + 1
        -- set score in memory
        dset(offset + ii, ord(sub(score.name, 1, 1)))
        dset(offset + ii + 1, ord(sub(score.name, 2, 2)))
        dset(offset + ii + 2, ord(sub(score.name, 3, 3)))
        dset(offset + ii + 3, score.val)
    end
end

function get_scores()
    return scores
end

function insert_score(name, score)
    -- keep scores sorted while inserting
    -- num_scores += 1
    -- add(scores, {name=name, val=score})
    i = 1
    for s=1, #scores do
        sc = scores[s]
        if score > sc.val then
            break
        end
        i += 1
    end
    add(scores, {name=name, val=score}, i)
    if #scores > max_scores then
        deli(scores, #scores)
    end
end