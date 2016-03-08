local math = math;
local tostring = tostring;
local table = table;

-- @brief 类的简单实现
function simpleclass(clzz)
	local obj = {};
	for k, v in pairs(clzz) do
		obj[k] = v;
	end
	return obj;
end

LinkClass = {}

function LinkClass:new(ntype,w,h)
	self.MAXX = w or 10;
	self.MAXY = h or 8;
	self.map = {};	-- [x][y] = tp;
	self.linkNode = {};
	self.mtype = ntype;
	return simpleclass(LinkClass);
end

function LinkClass:mx() return self.MAXX; end
function LinkClass:my() return self.MAXY;end
function LinkClass:getMap() return self.map; end

function LinkClass:build()
	
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	local my = self.MAXY;
	local mx = self.MAXX;
	local m = self.map;

	local typeNum = self.mtype;
	local total = my * mx;
	local rd = {};
	for i = 1, total, 2 do
		local r = math.random(1, typeNum);
		rd[i] = r;
		rd[i + 1] = r;
	end
	
	local tmp = 0;
	for i = 1, total, 2 do
		local j = math.random(1, total);
		tmp = rd[i];
		rd[i] = rd[j];
		rd[j] = tmp;
	end

	k = 1;
	for i = 1, mx do
		for j = 1, my do
			if (m[i] == nil) then
				m[i] = {};
			end
			-- 边缘一圈空出来
			if (i == 1 or j == 1 or i == mx or j == my) then
				m[i][j] = -1;
			else
				m[i][j] = rd[k];
			end
			k = k + 1;
		end
	end
	-- 测试的时候,直接填写具体的处理
	--self.map = {{-1,-1,-1,-1,-1,-1,-1,-1},{-1,24,25,4,6,14,14,-1},{-1,15,8,15,4,8,10,-1},{-1,24,2,4,16,5,10,-1},{-1,8,17,18,27,6,10,-1},{-1,4,5,2,12,27,18,-1},{-1,10,27,14,12,27,14,-1},{-1,18,10,18,14,15,10,-1},{-1,18,7,7,3,10,4,-1},{-1,-1,-1,-1,-1,-1,-1,-1}}
end

-- @brief 检测p1, p2在x方向上是否可以连接
function LinkClass:checkX(p1, p2)
	if math.abs(p1.x - p2.x) == 1 then
		return true;
	end
	
	local minx = math.min(p1.x, p2.x);
	local maxx = math.max(p1.x, p2.x);
	local mp = self.map;
	local j = p1.y;
	for i = minx + 1, maxx - 1 do
		if (mp[i][j] > 0) then
			return false;
		end
	end
	return true;
end

-- @brief 检测p1, p2在y方向上是否可以连接
function LinkClass:checkY(p1, p2)
	if math.abs(p1.y - p2.y) == 1 then
		return true;
	end
	local miny = math.min(p1.y, p2.y);
	local maxy = math.max(p1.y, p2.y);
	local mp = self.map;
	local i = p1.x;
	for j = miny + 1, maxy - 1 do
		if (mp[i][j] > 0) then
			return false;
		end
	end
	return true;
end

-- @brief 获取p的x方向上的可以行走的距离
function LinkClass:searchY(p)
	local mp = self.map;
	local i = p.x;
	local miny = p.y;
	local maxy = p.y;
	if (miny > 1) then
		for j = miny - 1, 1, -1 do
			if (mp[i][j] > 0) then
				break;
			end
			miny = j;
		end
	end
	if (maxy < self.MAXY) then
		for j = maxy + 1, self.MAXY, 1 do
			if (mp[i][j] > 0) then
				break;
			end
			maxy = j;
		end
	end
	return miny, maxy;
end

-- @brief 获取p的x方向上的可以行走的距离
function LinkClass:searchX(p)
	local mp = self.map;
	local j = p.y;
	local minx = p.x;
	local maxx = p.x;
	if (minx > 1) then
		for i = minx - 1, 1, -1 do
			if (mp[i][j] > 0) then
				break;
			end
			minx = i;
		end
	end
	if (maxx < self.MAXX) then
		for i = maxx + 1, self.MAXX, 1 do
			if (mp[i][j] > 0) then
				break;
			end
			maxx = i;
		end
	end
	return minx, maxx;
end


function LinkClass:clearLinkNode()
	self.linkNode = {};
end
-- @brief 添加一个转折点
function LinkClass:addLinkNode(x, y)
	table.insert(self.linkNode, {x = x, y = y});
end

function LinkClass:removePairs(p1, p2)
	local m = self.map;
	m[p1.x][p1.y] = -1;
	m[p2.x][p2.y] = -1;
end

-- @brief 打印连接点
function LinkClass:toString()
	local l = self.linkNode;
	local str = '';
	for k, v in ipairs(l) do
		str = str .. "("..v.x..","..v.y..")>";
	end
	return str;
end

-- 打印整个的列表
function LinkClass:mapToString()
	local mp = self.map;
	local tt = {};
	for i , v in ipairs(mp) do
		table.insert(tt, "{"..table.concat(v, ",").."}");
	end
	return "{"..table.concat(tt, ",").."}";
end

function LinkClass:checkNoBroken(p1, p2)
	self:clearLinkNode();
	-- 1.(p1)|    2. (p1) --- (p2)
	--       |
	--   (p2)|
	if ((p1.x == p2.x and self:checkY(p1, p2)) or (p1.y == p2.y and self:checkX(p1, p2))) then
		self:addLinkNode(p1.x, p1.y);
		self:addLinkNode(p2.x, p2.y);
		return true;
	end
	return false;
end

function LinkClass:checkOneBroken(p1, p2)
	self:clearLinkNode();
	-- 1.(p2)--|--(p2)
	--		   |      
	--     (p1)|      
	local miny, maxy = self:searchY(p1);
	if (miny <= p2.y and p2.y <= maxy) then
		local p = {x = p1.x, y = p2.y};
		if (self:checkX(p, p2)) then
			self:addLinkNode(p1.x, p1.y);
			self:addLinkNode(p.x, p.y);
			self:addLinkNode(p2.x, p2.y);
			return true;
		end
	end
	--2.   (p2)|
	--         |
	--  (p1)---|---(p1)
	miny, maxy = self:searchY(p2);
	if (miny <= p1.y and p1.y <= maxy) then
		local p = {x = p2.x, y = p1.y};
		if (self:checkX(p, p1)) then
			self:addLinkNode(p1.x, p1.y);
			self:addLinkNode(p.x, p.y);
			self:addLinkNode(p2.x, p2.y);
			return true;
		end
	end
	return false;
end

function LinkClass:checkTwoBroken(p1, p2)
	local m = self.map;
	--[[
	 1.   *|---(p2)      -->  (p1)---|
		   |                         |
	(p1)---|*                 (p2)---|
	--]]
	
	local minx1, maxx1 = self:searchX(p1);
	local minx2, maxx2 = self:searchX(p2);

	local minx = math.max(minx1, minx2);
	local maxx = math.min(maxx1, maxx2);
	local miny = math.min(p1.y, p2.y);
	local maxy = math.max(p1.y, p2.y);
	
	self:clearLinkNode();
	--print("==1x==>minx1:"..minx1..",maxx1:"..maxx1..",minx2:"..minx2..",maxx2:"..maxx2);
	--print("==1==>minx:"..minx..",maxx:"..maxx..",miny:"..miny..",maxy:"..maxy);
	for i = minx, maxx do
		local bfound = true;
		for j = miny, maxy do
			if (m[i][j] > 0) then
				bfound = false;
				break;
			end
		end
		if (bfound) then
			self:addLinkNode(p1.x, p1.y);
			self:addLinkNode(i, miny);
			self:addLinkNode(i, maxy);
			self:addLinkNode(p2.x, p2.y);
			return true;
		end
	end
	--[[
	 2.     |(p2)        (p1)|    |(p2)
		|---|                |    |
	(p1)|                    |----|
	--]]
	local miny1, maxy1 = self:searchY(p1);
	local miny2, maxy2 = self:searchY(p2);
	miny = math.max(miny1, miny2);
	maxy = math.min(maxy1, maxy2);
	minx = math.min(p1.x, p2.x);
	maxx = math.max(p1.x, p2.x);
	--print("==2==>minx:"..minx..",maxx:"..maxx..",miny:"..miny..",maxy:"..maxy);
	for j = miny, maxy do
		local bfound = true;
		for i = minx, maxx do
			if (m[i][j] > 0) then
				bfound = false;
				break;
			end
		end
		if (bfound) then
			self:addLinkNode(p1.x, p1.y);
			self:addLinkNode(minx, j);
			self:addLinkNode(maxx, j);
			self:addLinkNode(p2.x, p2.y);
			return true;
		end
	end
	return false;
end

function LinkClass:checkLink(p1, p2)

	if (self:checkNoBroken(p1, p2)) then
		return true;
	end

	if (self:checkOneBroken(p1, p2)) then
		return true;
	end

	if (self:checkTwoBroken(p1, p2)) then
		return true;
	end

	return false;
end


return LinkClass;

