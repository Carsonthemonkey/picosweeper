num_scores = 0
max_scores = 0
scores = {}
offset = 0
-- Cartdata must be initialized first
function init_scores(max_score_num, mem_offset)
    -- assert scores will fit in cartdata
    assert((max_scores * 4) + mem_offset + 1 < 64, "Failed to allocate in cart memory")
    offset = mem_offset
    max_scores = max_score_num
    num_scores = dget(mem_offset)
    for i=mem_offset + 1, num_scores * 4, 4 do
        name = chr(dget(i)) .. chr(dget(i + 1)) .. chr(dget(i + 2))
        score = dget(i + 3)
        insert_score(name, score)
    end
end


-- Return true if the score would be in top saved scores
function is_high_score(score)
    -- Compare to lowest
    return score > scores[max_scores]
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
        dset(offset + ii, sub(score.name, 0, 0))
        dset(offset + ii + 1, sub(score.name, 1, 1))
        dset(offset + ii + 2, sub(score.name, 1, 1))
        dset(offset + i + 3, score.val)
    end
end

function get_scores()
    return scores
end

function insert_score(name, score)
    -- keep scores sorted while inserting
    if #scores == 0 then
        add(scores, {name=name, val=score})
    else
        for i, s in pairs(scores) do
            if i > max_scores then
                return
            end
            if score > s.val then
                add(scores, {name=name, val=score}, i)
            end
        end
    end
end