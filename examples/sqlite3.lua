local ffi = package.preload.ffi()
local sqlite = require 'ffi.sqlite3.sqlite3' ('ffi/sqlite3/libs/windows/sqlite3.dll')

local tinsert = table.insert
local sqldb = {}
local SQLITE = sqlite.const

sqldb.init 	= function(self)
	-- Make an in-memory sqlite db
	self.code, self.db = sqlite.open(':memory:')
	if self.code ~= SQLITE.OK then
		print('Error: ' .. self.db:errmsg())
		os.exit()	-- This exits the Application
	end

	-- Make a table for tracking our go's 
	self.code = sqlite.exec(self.db, [[ CREATE TABLE GameObjects (
			id   INTEGER PRIMARY KEY,
			posx DOUBLE,
			posy DOUBLE,
			dir DOUBLE
	); ]])
end

sqldb.save = function(self, filename )

	self.code, self.newdb = sqlite.open(filename)
	if self.code ~= SQLITE.OK then
		print('Error: ' .. self.db:errmsg())
		os.exit()	-- This exits the Application
	end

	local backup = sqlite.backup_init(self.newdb, "main", self.db, "main") 
	if(backup) then 
		sqlite.backup_step(backup, -1) 
		sqlite.backup_finish(backup)
	end
	self.newdb:close()
end

sqldb.load = function(self, filename )

	self.code, self.newdb = sqlite.open(filename)
	if self.code ~= SQLITE.OK then
		print('Error: ' .. self.db:errmsg())
		os.exit()	-- This exits the Application
	end

	local backup = sqlite.backup_init(self.db, "main", self.newdb, "main") 
	if(backup) then 
		sqlite.backup_step(backup, -1) 
		sqlite.backup_finish(backup)
	end
	self.newdb:close()
end

sqldb.filldb = function( self, count, spread )
	local halfspr = spread/2
	
	do
	self.some_data = {}
	for i=1, count/2 do 
		local newobj = { posx = math.random() * spread -halfspr, posy = math.random() * spread -halfspr, dir = math.random() * math.pi * 2 }
		table.insert(self.some_data, newobj)
	end

	self.code, self.stmt = sqlite.prepare_v2(self.db, [[
	INSERT INTO GameObjects (posx, posy, dir) VALUES (?, ?, ?);
	]])

	for _, row in pairs(self.some_data) do
		sqlite.bind_double(self.stmt, 1, row.posx)
		sqlite.bind_double(self.stmt, 2, row.posy)
		sqlite.bind_double(self.stmt, 3, row.dir)
		sqlite.step(self.stmt)
		sqlite.reset(self.stmt)
	end

	sqlite.finalize(self.stmt)
	end

	do
	-- Using prepared statement in simplified way
	-- Statement prepared and finalized automatically

	self.another_data = {}
	for i=1, count/2 do 
		local newobj = { posx = math.random() * spread -halfspr, posy = math.random() * spread -halfspr, dir = math.random() * math.pi * 2 }
		table.insert(self.another_data, newobj)
	end

	self.code = sqlite.using_stmt(self.db, 'INSERT INTO GameObjects (posx, posy, dir) VALUES (?, ?, ?);', function (db, stmt)
		for _, row in pairs(self.another_data) do
			sqlite.bind_double(stmt, 1, row.posx)
			sqlite.bind_double(stmt, 2, row.posy)
			sqlite.bind_double(stmt, 3, row.dir)
			sqlite.step(stmt)
			sqlite.reset(stmt)
		end
	end)
	end
end

sqldb.updatedb = function(self, tablename, objs)
	do
		self.code = sqlite.using_stmt(self.db, 'UPDATE '..tablename..' SET posx = ?, posy = ?, dir = ? WHERE id = ?;', function (db, stmt)
			for _, row in pairs(objs) do
				sqlite.bind_double(stmt, 1, row.x)
				sqlite.bind_double(stmt, 2, row.y)
				sqlite.bind_double(stmt, 3, row.dir)
				sqlite.bind_int(stmt, 4, row.id)
				sqlite.step(stmt)
				sqlite.reset(stmt)
			end
		end)
	end
end

sqldb.dumptable = function(self, tablename)
	local objs = {}
	do
		for stmt in sqlite.using_stmt_iter(self.db, 'SELECT id, posx, posy, dir FROM '..tablename..';') do
			tinsert(objs, { id=sqlite.column_int(stmt, 0), x=sqlite.column_double(stmt, 1), y=sqlite.column_double(stmt, 2), dir=sqlite.column_double(stmt, 3)  } )
		end
	end
	return objs
end


sqldb.filterdb = function(self, filter)
	local objs = {}
	do
		sqlite.using_stmt_loop(self.db, 'SELECT id, posx, posy, dir FROM GameObjects WHERE '..filter..';', function (db, stmt)
			tinsert(objs, { id=sqlite.column_int(stmt, 0), x=sqlite.column_double(stmt, 1), y=sqlite.column_double(stmt, 2), dir=sqlite.column_double(stmt, 3) } )
		end)
	end
end

sqldb.final = function(self)
	self.db:close()
end

return sqldb