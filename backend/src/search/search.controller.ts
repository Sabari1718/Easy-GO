import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { SearchService } from './search.service';

@ApiTags('Search')
@Controller('search')
export class SearchController {
  constructor(private searchService: SearchService) {}

  @Get()
  @ApiOperation({ summary: 'Search buses, routes, and stops' })
  @ApiQuery({ name: 'q', description: 'Search query (bus number, route, stop name)' })
  search(@Query('q') q: string) {
    return this.searchService.search(q);
  }
}
