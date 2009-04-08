class Map
  Infinity = 1.0 / 0
  TEX_WIDTH  = 64
  TEX_HEIGHT = 64
  GRID_WIDTH_HEIGHT = 64
  
  attr_accessor :matrix
  attr_reader   :window
  attr_reader   :textures
  attr_reader   :sprites
  
  # @require for i in 0...matrix_row_column.size:
  #   matrix_row_column[i].size == matrix_row_column[i+1].size
  def initialize(matrix_row_column, texture_files, sprites, window)
    @matrix = matrix_row_column
    @window = window
    @textures = [nil]
    texture_files.each {|tex_file|
      pair = {}
      
      tex_file.each_pair {|tex_type, tex_path|
        pair[tex_type] = Gosu::Image::load_tiles(window, tex_path, 1, TEX_HEIGHT, false)
      }
      
      @textures << pair
    }
    
    @sprites = sprites
  end
  
  def find_nearest_intersection(start_x, start_y, angle)
    hor_x, hor_y = find_horizontal_intersection(start_x, start_y, angle)
    ver_x, ver_y = find_vertical_intersection(start_x, start_y, angle)
    
    hor_r = Math.sqrt( (hor_x - start_x) ** 2 + (hor_y - start_y) ** 2 )
    ver_r = Math.sqrt( (ver_x - start_x) ** 2 + (ver_y - start_y) ** 2 )
    
    if hor_r < ver_r
      return :horizontal, hor_r, hor_x, hor_y
    else
      return :vertical, ver_r, ver_x, ver_y
    end
  end
  
  def find_horizontal_intersection(start_x, start_y, angle)
    # When the angle is horizontal, we will never find a horizontal intersection.
    # After all, the ray would then be considered parallel to any possible horizontal wall.
    return Infinity, Infinity if angle == 0 || angle == 180
    
    grid_y = (start_y / GRID_WIDTH_HEIGHT).to_i
    
    if(angle > 0 && angle < 180)
      # Ray facing upwards
      ay = (grid_y * GRID_WIDTH_HEIGHT) - 1
    else
      # Ray facing downwards
      ay = ( grid_y + 1 ) * GRID_WIDTH_HEIGHT
    end
    
    ax = start_x + (start_y - ay) / Math.tan(angle * Math::PI / 180)
    
    return Infinity, Infinity if(ax < 0 || ax > 640 || ay < 0 || ay > 480)
    
    if(!hit?(ax, ay))
      # Extend the ray
      return find_horizontal_intersection(ax, ay, angle)
    else
      return ax, ay
    end
  end
  
  def find_vertical_intersection(start_x, start_y, angle)
    return Infinity, Infinity if angle == 90 || angle == 270
       
    grid_x = (start_x / GRID_WIDTH_HEIGHT).to_i
        
    if(angle > 90 && angle < 270)
      # Ray facing left
      bx = (grid_x * GRID_WIDTH_HEIGHT) - 1
    else
      # Ray facing right
      bx = (grid_x + 1) * GRID_WIDTH_HEIGHT
    end
    
    by = start_y + (start_x - bx) * Math.tan(angle * Math::PI / 180)
    
    # If the casted ray gets out of the playfield, emit infinity.
    return Infinity, Infinity if(bx < 0 || bx > 640 || by < 0 || by > 480)
    
    if(!hit?(bx, by))
      #Extend the ray
      return find_vertical_intersection(bx, by, angle)
    else
      return bx, by
    end
  end
  
  def texture_for(type, x, y, angle)
    column = (x / GRID_WIDTH_HEIGHT).to_i
    row    = (y / GRID_WIDTH_HEIGHT).to_i
    
    texture_id = @matrix[row][column]
    
    return @textures[texture_id][:south][x % TEX_WIDTH] if type == :horizontal and angle < 180
    return @textures[texture_id][:north][(TEX_WIDTH - x) % TEX_WIDTH] if type == :horizontal and angle > 180
    return @textures[texture_id][:west][(TEX_HEIGHT - y) % TEX_HEIGHT] if type == :vertical and ( angle > 90 and angle < 270 )
    return @textures[texture_id][:east][y % TEX_HEIGHT] if type == :vertical and ( angle < 90 or angle > 270 )
  end
  
  def walkable?(row, column)
    return @matrix[row][column] == 0
  end
  
  def hit?(x,y)
    column = (x / GRID_WIDTH_HEIGHT).to_i
    row    = (y / GRID_WIDTH_HEIGHT).to_i
    
    return !walkable?(row, column)
  end
  
end